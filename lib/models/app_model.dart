import 'package:binding/binding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AppModel extends NotifyPropertyChanged {
  static const usersPropertyName = 'users';
  List<UserModel> _users;
  List<UserModel> get users => _users;

  void addUser({String name, String id, int patchTime}) {
    _users.add(UserModel(name: name, userId: id, patchTimePerDay: patchTime));
    _save();
  }

  void removeUser({String id}) {
    _users.removeWhere((user) => user.userId == id);
    _save();
  }

  void updateUser({String id, String name, int patchTime}) {
    final user = _users.firstWhere((user) => user.userId == id);
    user.name = name;
    user.patchTimePerDay = patchTime;
    _save();
  }

  Future<void> _save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        usersPropertyName,
        users
            .map((item) =>
                '${item.name}***${item.userId}***${item.patchTimePerDay}')
            .toList());
    propertyChanged(propertyName: usersPropertyName);
  }

  Future<void> loadUsers() async {
    _users = List<UserModel>();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(usersPropertyName)) {
      for (var item in prefs.getStringList(usersPropertyName)) {
        var values = item.split('***');
        _users.add(UserModel(
            name: values[0],
            userId: values[1],
            patchTimePerDay: int.parse(values[2])));
      }
    }
    propertyChanged(propertyName: usersPropertyName);
  }
}
