class EndPoint {
  static String baseUrl = "http://vstore.runasp.net/api/";
  static String signIn = "Account/Login";
  static String signUp = "Account/user/signup";
  static String ForgotPassword="Account/ForgotPassword";
  static String getUserDataEndPoint(id) {
    return "user/get-user/$id";
  }
}

class ApiKey {
  static String status = "status";
  static String errorMessage = "ErrorMessage";
  static String Email = "Email";
  static String Password = "Password";
  static String token = "token";
  static String message = "message";
  static String id = "id";
  static String name = "name";
  static String phone = "phone";
  static String confirmPassword = "confirmPassword";
  static String location = "location";
  static String profilePic = "profilePic";

  static var isOwner;
}