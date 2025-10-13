class LineChartDataModel {
  LineChartDataModel(this.year, this.sales);

  int year;
  double sales;

  @override
  String toString() {
    return '{$sales}';
  }
}
