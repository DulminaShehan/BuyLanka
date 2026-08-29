class RiderEarningsModel {
  final double todayEarnings;
  final int todayDeliveriesCount;
  final double weeklyEarnings;
  final int weeklyDeliveriesCount;
  final double monthlyEarnings;
  final int monthlyDeliveriesCount;
  final double totalEarnings;
  final int totalDeliveriesCount;

  const RiderEarningsModel({
    this.todayEarnings = 0.0,
    this.todayDeliveriesCount = 0,
    this.weeklyEarnings = 0.0,
    this.weeklyDeliveriesCount = 0,
    this.monthlyEarnings = 0.0,
    this.monthlyDeliveriesCount = 0,
    this.totalEarnings = 0.0,
    this.totalDeliveriesCount = 0,
  });
}
