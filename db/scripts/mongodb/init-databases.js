/**
 * MongoDB Database Initialization Script
 * ======================================
 * Creates databases, application users, and bootstrap markers for:
 *   - junttus
 *   - ecommerce_scraper
 *   - k3s_cluster
 *   - dicaboa
 *
 * IMPORTANT: This script is designed to run via MongoDB Docker entrypoint
 *            /docker-entrypoint-initdb.d/ which executes scripts as the
 *            root/admin user BEFORE auth is fully enabled, OR manually
 *            against an authenticated admin session.
 *
 * Docker usage (already mounted in dbs.yaml):
 *   volumes:
 *     - ./scripts/mongodb/init-databases.js:/docker-entrypoint-initdb.d/init-databases.js:ro
 *
 * Manual usage:
 *   mongosh -u root -p <password> --authenticationDatabase admin < init-databases.js
 */

(function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // CONFIGURATION — add new databases here
  // ---------------------------------------------------------------------------
  var DATABASES = [
    { name: 'junttus',           user: 'junttus_app' },
    { name: 'ecommerce_scraper', user: 'scraper_app' },
    { name: 'k3s_cluster',       user: 'k3s_app' },
    { name: 'dicaboa',           user: 'dicaboa_app' }
  ];

  // ---------------------------------------------------------------------------
  // PASSWORD RESOLUTION
  // ---------------------------------------------------------------------------
  // When running via Docker entrypoint, MONGO_INITDB_ROOT_PASSWORD is the
  // shared secret. We derive app passwords from the same secret by convention,
  // OR you can set explicit per-DB env vars. For production, use distinct
  // secrets injected by your secrets manager.
  //
  // Priority:
  //   1. MONGO_PASS_<DB_NAME>  (explicit per-DB secret)
  //   2. MONGO_INITDB_ROOT_PASSWORD  (shared secret fallback)
  // ---------------------------------------------------------------------------

  function getEnv(name) {
    // In mongosh/mongo shell, environment variables are NOT accessible.
    // The Docker entrypoint sources them as shell vars before invoking mongo.
    // We rely on the global scope where the entrypoint may have injected them.
    if (typeof globalThis !== 'undefined' && globalThis[name] !== undefined) {
      return globalThis[name];
    }
    if (typeof global !== 'undefined' && global[name] !== undefined) {
      return global[name];
    }
    // Docker entrypoint sets process.env in some contexts
    if (typeof process !== 'undefined' && process.env && process.env[name]) {
      return process.env[name];
    }
    return null;
  }

  function getPassword(dbName) {
    var envVar = 'MONGO_PASS_' + dbName.toUpperCase().replace(/[^A-Z0-9]/g, '_');
    var pwd = getEnv(envVar);

    if (!pwd) {
      // Fallback to shared root password for local/dev environments
      pwd = getEnv('MONGO_INITDB_ROOT_PASSWORD');
    }

    if (!pwd) {
      print('ERROR: No password available for database "' + dbName + '".');
      print('       Set either ' + envVar + ' or MONGO_INITDB_ROOT_PASSWORD.');
      quit(1);
    }

    return pwd;
  }

  function userExists(dbConn, username) {
    var result = dbConn.getUsers();
    var users = (result && result.users) ? result.users : [];
    for (var i = 0; i < users.length; i++) {
      if (users[i].user === username) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // MAIN
  // ---------------------------------------------------------------------------

  print('MongoDB init started: ' + new Date().toISOString());

  DATABASES.forEach(function (cfg) {
    var dbConn = db.getSiblingDB(cfg.name);
    var password = getPassword(cfg.name);

    if (userExists(dbConn, cfg.user)) {
      print('  [SKIP] User "' + cfg.user + '" already exists in "' + cfg.name + '"');
    } else {
      dbConn.createUser({
        user: cfg.user,
        pwd: password,
        roles: [{ role: 'readWrite', db: cfg.name }],
        mechanisms: ['SCRAM-SHA-256'],
        passwordDigestor: 'server'
      });
      print('  [OK] Created user "' + cfg.user + '" in "' + cfg.name + '"');
    }

    // Materialise the database with a bootstrap marker
    // Use getCollection() instead of dbConn._init for mongosh compatibility
    dbConn.getCollection('_init').updateOne(
      { _init: 'database_created' },
      { $setOnInsert: { database: cfg.name, initializedAt: new Date() } },
      { upsert: true }
    );
  });

  print('MongoDB init finished: ' + new Date().toISOString());
})();
