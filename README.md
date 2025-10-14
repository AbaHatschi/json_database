# JSON Database

A lightweight JSON-based database for Flutter applications with MVVM architecture support and repository pattern.

## Features

- **🗄️ JSON Storage**: Simple file-based database with no external dependencies
- **🔧 CRUD Operations**: Complete Create, Read, Update, Delete functionality
- **🏛️ Repository Pattern**: Clean architecture with abstract repository classes
- **� MVVM Support**: Seamless integration with MVVM architectures
- **🔍 Query Builder**: Flexible queries with conditions and sorting
- **🔄 Auto-Increment**: Automatic ID generation for new records
- **💾 Persistent Storage**: Automatic saving and loading of data
- **🎯 Type Safety**: Generic implementation for better type safety

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  json_database:
    git:
      url: https://github.com/YourUsername/json_database.git
```

## Quick Start

### 1. Initialize Database

```dart
import 'package:json_database/json_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseEngine.instance.initialize(
    databaseName: 'my_app_db'
  );
  
  runApp(MyApp());
}
```

### 2. Create Data Model

```dart
class User extends DatabaseModel {
  @override
  int? id;
  
  final String name;
  final String email;
  final int age;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.age,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'age': age,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    age: json['age'],
  );
}
```

### 3. Create Repository

```dart
class UserRepository extends BaseRepository<User> {
  UserRepository() : super('users');

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  // Additional specific methods
  List<User> findByAge(int minAge) {
    return findWhere({'age': minAge});
  }
}
```

### 4. Use with MVVM

```dart
class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  List<User> _users = [];
  
  List<User> get users => _users;

  Future<void> loadUsers() async {
    _users = _repository.findAll();
    notifyListeners();
  }

  Future<void> addUser(String name, String email, int age) async {
    final user = User(name: name, email: email, age: age);
    await _repository.create(user);
    await loadUsers();
  }
}
```

### 5. Query Builder

```dart
final queryBuilder = QueryBuilder('users');
final results = queryBuilder
  .where('age', '>', 18)
  .where('name', 'LIKE', 'John%')
  .orderBy('age', OrderDirection.desc)
  .limit(10)
  .execute();
```

## Architecture

The package follows clean architecture principles:

- **DatabaseEngine**: Singleton main class for database operations
- **DatabaseModel**: Interface for all data models
- **BaseRepository**: Abstract base for repository implementations
- **CrudOperations**: CRUD operations with typed API
- **QueryBuilder**: Flexible query construction
- **StorageProvider**: Abstraction layer for storage

## Documentation

Further examples and detailed documentation can be found in the `/example` folders of the respective components.

## Contributions

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Create a pull request

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

**Summary:**
- ✅ Free for personal, educational, commercial, and open-source projects
- ✅ Modifications and contributions welcome
- ✅ Commercial use permitted without restrictions
- ✅ Can be used, copied, modified, and distributed freely

## Report Issues

For issues or feature requests, please create an [Issue](https://github.com/YourUsername/json_database/issues).
