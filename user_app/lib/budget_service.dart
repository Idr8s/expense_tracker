import 'package:cloud_firestore/cloud_firestore.dart';
import 'budget_model.dart';

class BudgetService {
  final FirebaseFirestore _fb = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String userId) => _fb
      .collection('users')
      .doc(userId)
      .collection('budget')
      .doc('current');

  /// CREATE / SET BUDGET (used on signup with user-supplied limit)
  Future<void> setBudget(String userId, BudgetModel budget) async {
    await _ref(userId).set(budget.toJson());
  }

  /// STREAM BUDGET (real-time UI)
  Stream<BudgetModel?> getBudget(String userId) {
    return _ref(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BudgetModel.fromJson(doc.data()!, doc.id);
    });
  }

  /// UPDATE ONLY SPENT VALUE (called when expenses change)
  Future<void> updateSpent(String userId, double spent) async {
    await _ref(userId).update({
      'spent':     spent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// UPDATE ONLY LIMIT VALUE (called from dashboard "Edit Budget" dialog)
  Future<void> updateLimit(String userId, double limit) async {
    await _ref(userId).update({
      'limit':     limit,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// GET ONCE (used on login/signup to check if doc exists)
  Future<DocumentSnapshot<Map<String, dynamic>>> getBudgetDoc(
      String userId) {
    return _ref(userId).get();
  }
}
