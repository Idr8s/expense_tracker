import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Streams for Dashboard
  Stream<int> getTotalUsersCount() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs.length);
  }

Stream<int> getTotalExpensesCount() {
  return _db.collectionGroup('expenses').snapshots()
      .map((snapshot) => snapshot.docs.length);
}

  // Get all users
  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  // Get all expenses
  Stream<List<ExpenseModel>> getExpenses() {
  return _db.collectionGroup('expenses')
      
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) =>
              ExpenseModel.fromJson(doc.data(), doc.id)).toList());
}

  // Delete user (Optional as per spec)
  Future<void> deleteUser(String userId) async {
    await _db.collection('users').doc(userId).delete();
    // In a real app, you might also want to delete their expenses and Firebase Auth user via Cloud Function.
  }
}
