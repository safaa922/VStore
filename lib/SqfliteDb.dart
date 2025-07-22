import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDb{
  initialDb() async{
    String databasePath= await getDatabasesPath();
    String path=join('databasePath','VStore.db');
    Database myDb=await openDatabase(path,onCreate: _onCreate);
    return myDb;
  }

  _onCreate(Database db,int version) async{
    await db.execute('''

    ''');

  }
}