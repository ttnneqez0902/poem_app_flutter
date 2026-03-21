// lib/widgets/clinical_chart_container.dart
class ClinicalChartContainer extends StatelessWidget {
  final LineChartData data;
  final bool isEmpty;

  const ClinicalChartContainer({super.key, required this.data, required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
      child: isEmpty
          ? const Center(child: Text("目前此指標無紀錄"))
          : LineChart(data),
    );
  }
}