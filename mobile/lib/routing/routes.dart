abstract final class Routes {
  static const launch = '/launch';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const chats = '/';
  static String chat(String id) => '/chat/$id';
  static const discover = '/discover';
  static const friends = '/friends';
  static String friend(String id) => '/friends/$id';
  static String character(String id) => '/discover/$id';
  static String photo(String characterId, String postId, {int index = 0}) =>
      '/discover/$characterId/photo/$postId?index=$index';
}
