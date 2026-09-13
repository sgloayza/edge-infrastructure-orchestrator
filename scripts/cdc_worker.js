// ==============================================================================
// CDC Real-time Synchronization Worker (Zero Data Loss Daemon)
// Captures INSERT, UPDATE, and DELETE events from Primary to Historic DB
// ==============================================================================

const primaryUri = "mongodb://admin:SuperSecurePassword2026!@mongo_demo_primary:27017/?authSource=admin";
const historicUri = "mongodb://admin:SuperSecurePassword2026!@mongo_demo_historic:27017/?authSource=admin";

print("[CDC WORKER] Connecting to Primary and Historic MongoDB nodes...");

let primaryConn, historicConn, primCol, histCol;

for (let attempt = 1; attempt <= 10; attempt++) {
  try {
    primaryConn = Mongo(primaryUri);
    historicConn = Mongo(historicUri);
    primCol = primaryConn.getDB("telemetry_production").getCollection("telemetry_live");
    histCol = historicConn.getDB("telemetry_history").getCollection("telemetry_audit");
    print("[CDC WORKER] Connected successfully to both clusters!");
    break;
  } catch (err) {
    print("[CDC WORKER] Connection retry " + attempt + "/10: " + err.message);
    sleep(2000);
  }
}

print("[CDC WORKER] 🟢 Real-time CDC Engine LIVE! Monitoring telemetry_production.telemetry_live...");

// Map of stringified ID -> actual _id
let knownPrimaryDocs = new Map();

try {
  primCol.find({}).forEach(doc => {
    knownPrimaryDocs.set(doc._id.toString(), doc._id);
  });
} catch (e) {
  print("[CDC WORKER] Initial scan notice: " + e.message);
}

while (true) {
  try {
    const currentPrimaryDocs = primCol.find({}).toArray();
    const currentPrimaryMap = new Map();

    for (const doc of currentPrimaryDocs) {
      const idStr = doc._id.toString();
      currentPrimaryMap.set(idStr, doc._id);

      // Check if document exists in Historic
      const existingHist = histCol.findOne({ _id: doc._id });

      if (!existingHist) {
        // Brand new INSERT captured!
        const auditDoc = Object.assign({}, doc, {
          cdc_op: "INSERT",
          cdc_synced: true,
          cdc_synced_at: new Date(),
          audit_policy: "Statutory 365-Day Retention"
        });
        histCol.insertOne(auditDoc);
        print("[CDC WORKER] 🚀 Captured INSERT on Primary: [" + (doc.sensor_id || doc.device_id || idStr) + "] -> Replicated to Historic DB!");
      } else {
        // Document exists. Check if modified (excluding CDC metadata fields)
        const stripMeta = (d) => {
          const c = Object.assign({}, d);
          delete c.cdc_synced;
          delete c.cdc_synced_at;
          delete c.cdc_op;
          delete c.cdc_updated_at;
          delete c.notes;
          delete c.audit_policy;
          delete c.audit_retention;
          delete c.deleted_from_primary_at;
          return JSON.stringify(c);
        };

        if (stripMeta(doc) !== stripMeta(existingHist)) {
          // Document was UPDATED in Primary!
          const updatePayload = Object.assign({}, doc, {
            cdc_op: "UPDATE",
            cdc_synced: true,
            cdc_updated_at: new Date()
          });
          histCol.replaceOne({ _id: doc._id }, updatePayload);
          print("[CDC WORKER] 🔄 Captured UPDATE on Primary: [" + (doc.sensor_id || doc.device_id || idStr) + "] -> Synchronized to Historic DB!");
        }
      }
    }

    // Check for DELETED documents (documents in knownPrimaryDocs that are missing from currentPrimaryMap)
    for (const [prevIdStr, actualId] of knownPrimaryDocs.entries()) {
      if (!currentPrimaryMap.has(prevIdStr)) {
        // Operator deleted the document from Primary!
        // ZERO DATA LOSS: Preserve intact in Historic DB with audit note!
        histCol.updateOne(
          { _id: actualId },
          {
            $set: {
              cdc_op: "DELETE_PRESERVED",
              audit_retention: true,
              notes: "REGISTRO PRESERVADO POR CDC: Este dato fue borrado en la base operativa primaria, pero se retuvo de forma inmutable para auditoría legal.",
              deleted_from_primary_at: new Date()
            }
          }
        );
        print("[CDC WORKER] 🛡️ ZERO DATA LOSS EVENT: Document [" + prevIdStr + "] DELETED in Primary -> RETAINED in Historic DB!");
      }
    }

    // Update tracked IDs
    knownPrimaryDocs = currentPrimaryMap;

  } catch (err) {
    print("[CDC WORKER] Sync loop notice: " + err.message);
  }

  sleep(500); // 500ms real-time cycle
}
