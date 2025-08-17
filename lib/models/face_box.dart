class FaceBox {
  final double x;
  final double y;
  final double width;
  final double height;

  FaceBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory FaceBox.fromJson(Map<String, dynamic> json) {
    return FaceBox(
      x: (json['_x'] as num).toDouble(),
      y: (json['_y'] as num).toDouble(),
      width: (json['_width'] as num).toDouble(),
      height: (json['_height'] as num).toDouble(),
    );
  }
}
