class ClashTraffic {
  final int totalUpload;
  final int totalDownload;
  final int currentUpload;
  final int currentDownload;
  const ClashTraffic({
    required this.totalUpload,
    required this.totalDownload,
    required this.currentUpload,
    required this.currentDownload,
  });

  static const zero = ClashTraffic(
    totalUpload: 0,
    totalDownload: 0,
    currentUpload: 0,
    currentDownload: 0,
  );
}
