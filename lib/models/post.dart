class Post {
  String title; // Title of the post
  String markdownContent; // Markdown format content

  Post({this.title = "", this.markdownContent = ""});

  // 필요한 경우 다른 메서드나 팩토리 생성자 추가
  Map<String, dynamic> toJson() => {
    'title': title,
    'markdownContent': markdownContent,
  };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    title: json['title'],
    markdownContent: json['markdownContent'],
  );
}
