import 'package:mysql_client/mysql_client.dart';

/// Central MySQL gateway for the whole app.
///
/// The Flutter desktop client talks straight to a local MySQL/MariaDB server
/// (XAMPP). On [init] it connects, then auto-creates every table the app needs
/// (`CREATE TABLE IF NOT EXISTS`) so the schema appears in phpMyAdmin without
/// any manual setup. If the connection fails (server down / wrong password)
/// the app keeps running — providers simply fall back to their in-memory seed.
///
/// To change credentials, edit the constants below.
class DbService {
  DbService._();
  static final DbService instance = DbService._();

  // --- Connection settings ---------------------------------------------------
  // XAMPP MariaDB runs on port 3307 here (MySQL 9.0 occupies 3306). The app
  // talks to MariaDB via a dedicated user (mysql_client needs a non-empty
  // password, so we use `posuser` rather than the empty-password root).
  static const String host = '127.0.0.1';
  static const int port = 3307;
  static const String user = 'posuser';
  static const String password = 'Pos@12345';
  static const String database = 'restaurant_pos';

  MySQLConnection? _conn;

  /// Whether a live MySQL connection is available.
  bool get isConnected => _conn != null;

  /// Connect and ensure the schema exists. Never throws — on failure it leaves
  /// [isConnected] false so the UI degrades gracefully.
  Future<void> init() async {
    try {
      final conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: user,
        password: password,
        databaseName: database,
        secure: false,
      );
      await conn.connect(timeoutMs: 6000);
      _conn = conn;
      await _createSchema();
      await _migrate();
    } catch (_) {
      _conn = null;
    }
  }

  /// Adds professional columns to existing installs (idempotent).
  Future<void> _migrate() async {
    const alters = [
      'ALTER TABLE customers ADD COLUMN IF NOT EXISTS address VARCHAR(255)',
      'ALTER TABLE customers ADD COLUMN IF NOT EXISTS city VARCHAR(64)',
      'ALTER TABLE customers ADD COLUMN IF NOT EXISTS dob VARCHAR(32)',
      'ALTER TABLE employees ADD COLUMN IF NOT EXISTS email VARCHAR(128)',
      'ALTER TABLE employees ADD COLUMN IF NOT EXISTS phone VARCHAR(64)',
      'ALTER TABLE employees ADD COLUMN IF NOT EXISTS cnic VARCHAR(32)',
      'ALTER TABLE employees ADD COLUMN IF NOT EXISTS join_date VARCHAR(32)',
      'ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS email VARCHAR(128)',
      'ALTER TABLE suppliers ADD COLUMN IF NOT EXISTS address VARCHAR(255)',
      "ALTER TABLE expenses ADD COLUMN IF NOT EXISTS invoice_file VARCHAR(255) DEFAULT ''",
      'ALTER TABLE orders ADD COLUMN IF NOT EXISTS data LONGTEXT NULL',
    ];
    for (final a in alters) {
      await exec(a);
    }
  }

  // --- Query helpers ---------------------------------------------------------

  /// Runs a write/DDL statement. Silently no-ops when disconnected.
  Future<void> exec(String sql, [Map<String, dynamic>? params]) async {
    final c = _conn;
    if (c == null) return;
    try {
      await c.execute(sql, params);
    } catch (_) {
      // Swallow so a single bad write never crashes the UI.
    }
  }

  /// Runs a SELECT and returns rows as column->value string maps.
  Future<List<Map<String, String?>>> rows(String sql,
      [Map<String, dynamic>? params]) async {
    final c = _conn;
    if (c == null) return const [];
    try {
      final result = await c.execute(sql, params);
      return result.rows.map((r) => r.assoc()).toList();
    } catch (_) {
      return const [];
    }
  }

  // --- Singleton state helpers (shift, settings, …) --------------------------

  /// Reads a single JSON blob keyed by [id] from `app_state` (null if absent).
  Future<String?> loadState(String id) async {
    final r = await rows('SELECT value FROM app_state WHERE id=:id', {'id': id});
    return r.isEmpty ? null : r.first['value'];
  }

  /// Writes a single JSON blob keyed by [id] into `app_state`.
  Future<void> saveState(String id, String value) => exec(
        'INSERT INTO app_state (id,value) VALUES (:id,:v) '
        'ON DUPLICATE KEY UPDATE value=:v',
        {'id': id, 'v': value},
      );

  // --- Schema ----------------------------------------------------------------

  Future<void> _createSchema() async {
    for (final stmt in _schema) {
      await exec(stmt);
    }
  }

  static const List<String> _schema = [
    '''
CREATE TABLE IF NOT EXISTS suppliers (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  contact VARCHAR(128),
  category VARCHAR(64),
  reliability DOUBLE DEFAULT 95,
  lead_days INT DEFAULT 2,
  outstanding_balance DOUBLE DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS customers (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(64),
  email VARCHAR(128),
  points INT DEFAULT 0,
  lifetime_spend DOUBLE DEFAULT 0,
  visits INT DEFAULT 0,
  last_visit_days INT DEFAULT 0,
  segment VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS employees (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(64),
  status VARCHAR(32),
  weekly_hours DOUBLE DEFAULT 0,
  basic_salary DOUBLE DEFAULT 0,
  allowances DOUBLE DEFAULT 0,
  deductions TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS expenses (
  id VARCHAR(64) PRIMARY KEY,
  category VARCHAR(32),
  vendor VARCHAR(255),
  amount DOUBLE DEFAULT 0,
  date_label VARCHAR(32),
  has_invoice TINYINT DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS reservations (
  id VARCHAR(64) PRIMARY KEY,
  guest_name VARCHAR(255) NOT NULL,
  phone VARCHAR(64),
  party_size INT DEFAULT 1,
  reserved_time DATETIME,
  table_name VARCHAR(32),
  status VARCHAR(32),
  note TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS menu_items (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DOUBLE DEFAULT 0,
  image TEXT,
  category VARCHAR(64),
  is_best_seller TINYINT DEFAULT 0,
  is_chef_choice TINYINT DEFAULT 0,
  is_veg TINYINT DEFAULT 0,
  sku VARCHAR(64),
  available TINYINT DEFAULT 1,
  variations TEXT,
  addons TEXT,
  happy_hour_price DOUBLE NULL,
  happy_hour_start INT NULL,
  happy_hour_end INT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS stock_items (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(64),
  category VARCHAR(32),
  quantity DOUBLE DEFAULT 0,
  unit VARCHAR(32),
  unit_cost DOUBLE DEFAULT 0,
  low_threshold DOUBLE DEFAULT 0,
  par_level DOUBLE DEFAULT 0,
  expiry DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS purchase_orders (
  id VARCHAR(64) PRIMARY KEY,
  po_number INT,
  supplier VARCHAR(255),
  status VARCHAR(32),
  created_at DATETIME,
  note TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS purchase_order_lines (
  id INT AUTO_INCREMENT PRIMARY KEY,
  po_id VARCHAR(64),
  item_id VARCHAR(64),
  name VARCHAR(255),
  unit VARCHAR(32),
  quantity DOUBLE,
  unit_cost DOUBLE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS restaurant_tables (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(32),
  seats INT,
  status VARCHAR(32),
  x DOUBLE DEFAULT 0,
  y DOUBLE DEFAULT 0,
  section VARCHAR(64)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS orders (
  id VARCHAR(64) PRIMARY KEY,
  bill_number VARCHAR(32),
  order_type VARCHAR(32),
  table_name VARCHAR(32) NULL,
  status VARCHAR(32),
  created_at DATETIME,
  subtotal DOUBLE DEFAULT 0,
  tax DOUBLE DEFAULT 0,
  discount DOUBLE DEFAULT 0,
  grand_total DOUBLE DEFAULT 0,
  payment_method VARCHAR(64) NULL,
  data LONGTEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS order_lines (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id VARCHAR(64),
  name VARCHAR(255),
  category VARCHAR(64),
  variation VARCHAR(64),
  modifiers TEXT,
  quantity INT,
  unit_price DOUBLE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS app_state (
  id VARCHAR(64) PRIMARY KEY,
  value LONGTEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS sales (
  id VARCHAR(64) PRIMARY KEY,
  table_label VARCHAR(64),
  payment_method VARCHAR(64),
  total DOUBLE DEFAULT 0,
  time DATETIME,
  status VARCHAR(32),
  cash_amount DOUBLE DEFAULT 0,
  card_amount DOUBLE DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
    '''
CREATE TABLE IF NOT EXISTS audit_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  category VARCHAR(32),
  action VARCHAR(255),
  detail TEXT,
  actor VARCHAR(128),
  at DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
''',
  ];
}
