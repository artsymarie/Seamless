// ================================================================
//  ARTSY PBR MATERIAL VENDOR  v1.4
//  Smart Lock  •  Countdown Display  •  Safe Refunds  •  Upgrades
// ------------------------------------------------
//  • Click once: previews & shows prices or redeliver option
//  • Countdown warns when vendor will reset
//  • Full automatic refunds for wrong, late, or invalid payments
//  • Experience KV persistence (permanent purchase record)
//  • Smart upgrades: pay only 40L to upgrade CM to FP
//
//  v1.4 changes
//  • Each grid square is renamed to its material name (slot index
//    is kept in the square's description as "slot_N"). Old
//    vendors with squares named "slot_N" migrate automatically.
//  • Root name/description stay stable and searchable: the
//    description is no longer overwritten with the last preview.
//  • A payment from a second customer is refunded without
//    cancelling the first customer's session.
//  • Owners of the Full Perm tier can't accidentally re-buy, and a
//    purchase record can no longer be downgraded FP -> CM.
//  • A material whose name ends in " 1" (e.g. "Stacked Stone 1")
//    is only treated as a Copy/Mod variant when its base exists.
//  • Debit permission is checked live (no stale flag after resale)
//    and only requested when missing.
//  • Clicking a different square while armed no longer leaves the
//    old pay buttons live for the new square.
//  • Experience KV errors are reported to the owner.
// ================================================================

// ---- PRICING ----
integer PRICE_COPYMOD = 60;
integer PRICE_FULL    = 100;
integer PRICE_UPGRADE = 40;  // Difference for upgrading from CM to FP

// ---- DISPLAY (Furware) ----
string DISPLAY_STYLE   = "c=white;a=center;tags=on;";
string MSG_NEED_SELECT = "SELECT A MATERIAL (click a square)\nThen pay the vendor.";
string fmtPrices() { return "L$" + (string)PRICE_COPYMOD + " CM  |  L$" + (string)PRICE_FULL + " FP"; }

// ---- PERSISTENT KEYS (linkset data) ----
string LSD_ROOT_NAME = "artsy_vendor_root_name";

// ---- STATE ----
integer currentPreviewIndex = -1;
integer selectionMade       = FALSE;

// Single-user lock
key lockedToUser = NULL_KEY;
integer lockExpiresAt = 0;
float lockTimeoutSec = 20.0;

// Hover text tracking
integer hoverTextLink = 0;

// Inventory/links
list materialUUIDs;
list materialNames;
list previewPrims;
list slotPrims;      // index = slot number, value = link number (0 = missing)

// Root prim original name
string ORIGINAL_ROOT_NAME;

// ---- REDELIVERY STATE ----
key pendingCheckUser = NULL_KEY;
integer pendingCheckIndex = -1;
integer redeliveryMode = FALSE;
string redeliveryTier = "";

// ---- KV transactions ----
key kvReadTrans = NULL_KEY;
list kvWrites;       // strided [query_id, description]

// ===============================
// Furware + Pay helpers
// ===============================
fw_conf(string s) { llMessageLinked(LINK_SET, 0, s, "fw_conf:main"); }
fw_show(string s) { llMessageLinked(LINK_SET, 0, s, "fw_data:main"); }
hidePay()         { llSetPayPrice(PAY_HIDE, [PAY_HIDE, PAY_HIDE, PAY_HIDE, PAY_HIDE]); }
showPay()         { llSetPayPrice(PAY_HIDE, [PRICE_COPYMOD, PRICE_FULL, PAY_HIDE, PAY_HIDE]); }
showPayUpgrade()  { llSetPayPrice(PAY_HIDE, [PRICE_UPGRADE, PAY_HIDE, PAY_HIDE, PAY_HIDE]); }

integer hasDebit() { return (llGetPermissions() & PERMISSION_DEBIT) != 0; }

// ===============================
// UV-safe material apply
// ===============================
restoreUVs(integer linkNum, list faceParams)
{
    integer i;
    for (i = 0; i < llGetListLength(faceParams); i += 4)
    {
        integer face   = llList2Integer(faceParams, i);
        vector  repeat = llList2Vector (faceParams, i+1);
        vector  offset = llList2Vector (faceParams, i+2);
        float   rot    = llList2Float  (faceParams, i+3);
        llSetLinkPrimitiveParamsFast(linkNum, [PRIM_TEXTURE, face, TEXTURE_BLANK, repeat, offset, rot]);
    }
}

applyMaterialPreserveUV(integer linkNum, key matUUID)
{
    integer faces = llGetLinkNumberOfSides(linkNum);
    list faceParams; integer f;
    for (f = 0; f < faces; ++f)
    {
        list t = llGetLinkPrimitiveParams(linkNum, [PRIM_TEXTURE, f]);
        faceParams += [f, llList2Vector(t,1), llList2Vector(t,2), llList2Float(t,3)];
    }
    llSetLinkPrimitiveParamsFast(linkNum, [PRIM_RENDER_MATERIAL, ALL_SIDES, matUUID]);
    restoreUVs(linkNum, faceParams);
}

// ===============================
// Experience KV Storage
// ===============================
string kvKey(key avatarKey, string matName)
{
    return (string)avatarKey + "|" + matName;
}

storePurchase(key who, string matName, string tier)
{
    string value = (string)llGetUnixTime() + "|" + tier;
    key q = llUpdateKeyValue(kvKey(who, matName), value, FALSE, "");
    kvWrites += [q, llKey2Name(who) + " (" + (string)who + ") " + matName + " " + tier];
}

checkIfPurchased(key who, integer matIndex)
{
    pendingCheckUser = who;
    pendingCheckIndex = matIndex;
    string matName = llList2String(materialNames, matIndex);
    kvReadTrans = llReadKeyValue(kvKey(who, matName));
}

// ===============================
// Lock + Smart Interaction
// ===============================
lockToUser(key who)
{
    if (lockedToUser == NULL_KEY || lockedToUser == who || !selectionMade)
    {
        lockedToUser = who;
        lockExpiresAt = llGetUnixTime() + (integer)lockTimeoutSec;
    }
}

unlockVendor()
{
    lockedToUser = NULL_KEY;
    lockExpiresAt = 0;
}

integer isLocked()
{
    if (lockedToUser == NULL_KEY) return FALSE;
    if (llGetUnixTime() >= lockExpiresAt)
    {
        unlockVendor();
        return FALSE;
    }
    return TRUE;
}

integer canUserInteract(key who)
{
    if (!isLocked()) return TRUE;
    if (lockedToUser == who) return TRUE;
    // Holder walked away before choosing (and no lookup is in flight).
    if (!selectionMade && pendingCheckUser == NULL_KEY)
    {
        unlockVendor();
        return TRUE;
    }
    return FALSE;
}

// ===============================
// Refund + Payment Safety
// ===============================
refund(key payer, integer amount, string reason)
{
    if (amount <= 0) return;
    if (hasDebit())
    {
        llGiveMoney(payer, amount);
        llInstantMessage(payer, "Payment returned. " + reason);
    }
    else
    {
        llInstantMessage(payer, "Payment could not be returned automatically. Contact the store owner for manual help.");
        llOwnerSay("Refund owed: L$" + (string)amount + " to " + llKey2Name(payer) + " (" + (string)payer + "). " + reason);
    }
}

// ===============================
// Selection flow
// ===============================
integer secondsLeft()
{
    integer r = lockExpiresAt - llGetUnixTime();
    if (r < 0) r = 0;
    return r;
}

showStatus()
{
    string matName = llList2String(materialNames, currentPreviewIndex);
    string remaining = "(" + (string)secondsLeft() + "s)";
    if (redeliveryMode)
    {
        if (redeliveryTier == "Copy/Mod")
            fw_show(matName + "\nOWNED: CM | Pay L$" + (string)PRICE_UPGRADE + " Upgrade to FP\n" + remaining);
        else
            fw_show(matName + "\nOWNED: FP\n" + remaining);
    }
    else if (selectionMade)
        fw_show(matName + "\n" + fmtPrices() + " " + remaining);
}

armForPurchase(string matName)
{
    selectionMade = TRUE;
    redeliveryMode = FALSE;
    redeliveryTier = "";
    showPay();
    // Root carries the material name while armed, so the payment shows up
    // under that name in the owner's transaction history.
    llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_NAME, matName]);
    showStatus();
    llSetTimerEvent(1.0);
}

armForRedelivery(string matName, string tier)
{
    selectionMade = TRUE;
    redeliveryMode = TRUE;
    redeliveryTier = tier;
    llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_NAME, matName]);

    // Set hover text on the selected square
    integer slotLink = llList2Integer(slotPrims, currentPreviewIndex);
    if (slotLink > 0)
    {
        llSetLinkPrimitiveParamsFast(slotLink, [PRIM_TEXT, "Click to Redeliver", <1,1,1>, 1.0]);
        hoverTextLink = slotLink;
    }

    // CM owners may upgrade; FP owners already have everything.
    if (tier == "Copy/Mod") showPayUpgrade();
    else hidePay();

    showStatus();
    llSetTimerEvent(1.0);
}

disarmPurchase()
{
    selectionMade = FALSE;
    redeliveryMode = FALSE;
    redeliveryTier = "";
    hidePay();
    fw_show(MSG_NEED_SELECT);
    llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_NAME, ORIGINAL_ROOT_NAME]);

    // Clear hover text
    if (hoverTextLink > 0)
    {
        llSetLinkPrimitiveParamsFast(hoverTextLink, [PRIM_TEXT, "", <1,1,1>, 0.0]);
        hoverTextLink = 0;
    }

    unlockVendor();
    llSetTimerEvent(0.0);
}

// ===============================
// Delivery
// ===============================
giveTier(key who, string matName, string tier, string verb)
{
    if (tier == "Full Perm")
    {
        llGiveInventory(who, matName);
        llInstantMessage(who, verb + " " + matName + " Full Perm. Thank you!");
        return;
    }
    string cm = matName + " 1";
    if (llGetInventoryType(cm) == INVENTORY_MATERIAL)
    {
        llGiveInventory(who, cm);
        llInstantMessage(who, verb + " " + matName + " Copy/Mod. Thank you!");
    }
    else
    {
        llGiveInventory(who, matName);
        llInstantMessage(who, "Copy/Mod variant not found. " + verb + " base material " + matName + ".");
        llOwnerSay("Missing Copy/Mod variant \"" + cm + "\" - gave base material instead.");
    }
}

// ===============================
// Core setup
// ===============================
scanInventory()
{
    materialUUIDs = [];
    materialNames = [];
    integer n = llGetInventoryNumber(INVENTORY_MATERIAL);
    integer i;
    for (i = 0; i < n && llGetListLength(materialUUIDs) < 16; ++i)
    {
        string nm = llGetInventoryName(INVENTORY_MATERIAL, i);
        // "X 1" is the Copy/Mod variant only when "X" itself exists,
        // so a material genuinely named "... 1" still gets a square.
        integer isVariant = FALSE;
        if (llGetSubString(nm, -2, -1) == " 1")
            isVariant = (llGetInventoryType(llGetSubString(nm, 0, -3)) == INVENTORY_MATERIAL);
        if (!isVariant)
        {
            key k = llGetInventoryKey(nm);
            if (k) { materialUUIDs += [k]; materialNames += [nm]; }
        }
    }
}

updateGridPreviews()
{
    integer i;
    integer max = llGetListLength(materialUUIDs);
    for (i = 0; i < max; ++i)
    {
        integer link = llList2Integer(slotPrims, i);
        if (link > 0) applyMaterialPreserveUV(link, llList2Key(materialUUIDs, i));
    }
}

// Squares are found by name "slot_N" (pre-1.4 vendors) or by description
// "slot_N" (1.4+). Each square is then named after its material so it is
// readable in Edit Linked / inspectors, with the slot kept in the description.
integer slotIndexOf(string s)
{
    if (llSubStringIndex(s, "slot_") != 0) return -1;
    return (integer)llGetSubString(s, 5, -1);
}

labelSlots()
{
    integer i;
    integer count = llGetListLength(slotPrims);
    for (i = 0; i < count; ++i)
    {
        integer link = llList2Integer(slotPrims, i);
        if (link > 0)
        {
            string tag = "slot_" + (string)i;
            string nm = tag;
            if (i < llGetListLength(materialNames)) nm = llList2String(materialNames, i);
            list cur = llGetLinkPrimitiveParams(link, [PRIM_NAME, PRIM_DESC]);
            if (llList2String(cur, 0) != nm || llList2String(cur, 1) != tag)
                llSetLinkPrimitiveParamsFast(link, [PRIM_NAME, nm, PRIM_DESC, tag]);
        }
    }
}

previewMaterial(integer index, key whoClicked)
{
    if (index < 0 || index >= llGetListLength(materialUUIDs)) return;

    // Clear any existing hover text
    if (hoverTextLink > 0)
    {
        llSetLinkPrimitiveParamsFast(hoverTextLink, [PRIM_TEXT, "", <1,1,1>, 0.0]);
        hoverTextLink = 0;
    }

    // A new click starts unarmed until the KV lookup answers.
    selectionMade = FALSE;
    redeliveryMode = FALSE;
    hidePay();

    currentPreviewIndex = index;
    key uuid = llList2Key(materialUUIDs, index);

    integer i;
    for (i = 0; i < llGetListLength(previewPrims); ++i)
    {
        integer linkNum = llList2Integer(previewPrims, i);
        applyMaterialPreserveUV(linkNum, uuid);
    }

    lockToUser(whoClicked);
    checkIfPurchased(whoClicked, index);
}

initLinks()
{
    previewPrims = [];
    slotPrims = [];
    integer links = llGetNumberOfPrims();
    integer i;
    for (i = 2; i <= links; ++i)
    {
        string nm = llGetLinkName(i);
        if (nm == "preview") previewPrims += [i];
        else
        {
            integer idx = slotIndexOf(nm);
            if (idx < 0) idx = slotIndexOf(llList2String(llGetLinkPrimitiveParams(i, [PRIM_DESC]), 0));
            if (idx >= 0)
            {
                while (llGetListLength(slotPrims) <= idx) slotPrims += [0];
                slotPrims = llListReplaceList(slotPrims, [i], idx, idx);
            }
        }
    }
}

integer isMaterialDerivedName(string s)
{
    integer i;
    for (i = 0; i < llGetListLength(materialNames); ++i)
        if (llSubStringIndex(s, llList2String(materialNames, i)) == 0) return TRUE;
    return FALSE;
}

// Remember the vendor's own name across resets. If the script reset while
// the root was showing a material name, fall back to the saved name.
initRootName()
{
    string cur = llGetLinkName(LINK_ROOT);
    string saved = llLinksetDataRead(LSD_ROOT_NAME);
    if (!isMaterialDerivedName(cur))
    {
        ORIGINAL_ROOT_NAME = cur;
        if (saved != cur) llLinksetDataWrite(LSD_ROOT_NAME, cur);
    }
    else if (saved != "") ORIGINAL_ROOT_NAME = saved;
    else ORIGINAL_ROOT_NAME = "[ARTSY] PBR Material Vendor";

    // v1.3 wrote the last previewed material into the description.
    // Replace that leftover with something searchable.
    string desc = llGetObjectDesc();
    if (desc == "" || llListFindList(materialNames, [desc]) != -1)
        llSetObjectDesc(ORIGINAL_ROOT_NAME + " - " + (string)llGetListLength(materialNames) + " PBR materials");
}

integer experienceReady()
{
    list d = llGetExperienceDetails(NULL_KEY);
    return (llGetListLength(d) >= 3);
}

init()
{
    fw_conf(DISPLAY_STYLE);
    fw_show("");
    hidePay();
    initLinks();
    scanInventory();
    labelSlots();
    initRootName();
    updateGridPreviews();
    currentPreviewIndex = -1;
    hoverTextLink = 0;
    kvReadTrans = NULL_KEY;
    kvWrites = [];
    unlockVendor();
    disarmPurchase();

    if (!experienceReady()) llOwnerSay("Warning: Vendor not running under an Experience.");
    if (!hasDebit()) llRequestPermissions(llGetOwner(), PERMISSION_DEBIT);
}

// ===============================
// EVENTS
// ===============================
default
{
    state_entry() { init(); }

    run_time_permissions(integer perm)
    {
        if (!(perm & PERMISSION_DEBIT))
            llOwnerSay("Debit permission was not granted - refunds will not be automatic.");
    }

    touch_start(integer n)
    {
        key who = llDetectedKey(0);
        integer link = llDetectedLinkNumber(0);
        string nm = llGetLinkName(link);
        integer idx = -1;
        if (link > 1) idx = llListFindList(slotPrims, [link]);

        if (idx < 0 && nm != "BUY") return;

        if (!canUserInteract(who))
        {
            llInstantMessage(who, "Vendor is in use. Please try again soon.");
            return;
        }

        if (idx >= 0)
        {
            if (redeliveryMode && currentPreviewIndex == idx && lockedToUser == who)
            {
                string matName = llList2String(materialNames, idx);
                giveTier(who, matName, redeliveryTier, "Redelivered:");
                disarmPurchase();
            }
            else previewMaterial(idx, who);
        }
        else if (nm == "BUY")
        {
            if (selectionMade && lockedToUser == who && !redeliveryMode) showPay();
        }
    }

    money(key id, integer amount)
    {
        // Someone else paid while another customer holds the vendor:
        // refund them and leave the active session alone.
        if (isLocked() && lockedToUser != id)
        {
            refund(id, amount, "Vendor is in use by another customer. Please try again in a moment.");
            return;
        }

        if (!isLocked() || !selectionMade || currentPreviewIndex < 0)
        {
            refund(id, amount, "Payment arrived after vendor timeout. Please reselect the material.");
            disarmPurchase();
            return;
        }

        string matName = llList2String(materialNames, currentPreviewIndex);

        if (redeliveryMode)
        {
            if (redeliveryTier == "Copy/Mod" && amount == PRICE_UPGRADE)
            {
                giveTier(id, matName, "Full Perm", "Upgraded to");
                storePurchase(id, matName, "Full Perm");
            }
            else refund(id, amount, "You already own " + matName + ". Click the square to redeliver it.");
        }
        else if (amount == PRICE_FULL)
        {
            giveTier(id, matName, "Full Perm", "Delivered");
            storePurchase(id, matName, "Full Perm");
        }
        else if (amount == PRICE_COPYMOD)
        {
            giveTier(id, matName, "Copy/Mod", "Delivered");
            storePurchase(id, matName, "Copy/Mod");
        }
        else refund(id, amount, "Use the on-screen buttons only.");

        disarmPurchase();
    }

    dataserver(key query_id, string data)
    {
        integer w = llListFindList(kvWrites, [query_id]);
        if (w != -1)
        {
            if (llGetSubString(data, 0, 0) != "1")
                llOwnerSay("Purchase record NOT saved (" + llGetExperienceErrorMessage((integer)llGetSubString(data, 2, -1)) + "): " + llList2String(kvWrites, w + 1));
            kvWrites = llDeleteSubList(kvWrites, w, w + 1);
            return;
        }

        if (query_id != kvReadTrans) return;
        key who = pendingCheckUser;
        integer idx = pendingCheckIndex;
        pendingCheckUser = NULL_KEY;
        pendingCheckIndex = -1;
        kvReadTrans = NULL_KEY;

        // Lookup came back after the customer timed out or moved on.
        if (who == NULL_KEY || idx != currentPreviewIndex || !isLocked() || lockedToUser != who) return;

        string matName = llList2String(materialNames, idx);

        if (llGetSubString(data, 0, 0) == "1")
        {
            list parts = llParseString2List(llGetSubString(data, 2, -1), ["|"], []);
            if (llGetListLength(parts) >= 2)
            {
                armForRedelivery(matName, llList2String(parts, 1));
                return;
            }
        }
        else
        {
            integer err = (integer)llGetSubString(data, 2, -1);
            if (err != XP_ERROR_KEY_NOT_FOUND)
                llOwnerSay("Purchase lookup failed (" + llGetExperienceErrorMessage(err) + ") for " + llKey2Name(who) + " / " + matName);
        }
        armForPurchase(matName);
    }

    timer()
    {
        if (!isLocked())
        {
            disarmPurchase();
            return;
        }
        showStatus();
    }

    changed(integer c)
    {
        if (c & CHANGED_OWNER) llResetScript();
        if (c & (CHANGED_INVENTORY | CHANGED_LINK | CHANGED_REGION_START)) init();
    }
}
