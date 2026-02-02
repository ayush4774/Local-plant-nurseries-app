class AuthRepository {
  Future<bool> signIn(String email, String password) async {
    // TODO: integrate with auth provider (Firebase / API)
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<bool> signUp(String email, String password) async {
    // TODO: integrate with auth provider (Firebase / API)
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
