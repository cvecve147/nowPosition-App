import 'dart:math';
nowPosition=[];

calculationPreDist(double x, double y) {
  double prePointX = nowPosition[nowPosition.length - 1].x;
  double prePointY = nowPosition[nowPosition.length - 1].y;
  double dist = sqrt(pow(prePointX - x, 2) + pow(prePointY - y, 2));
  return dist;
}

double dist = calculationPreDist(X, Y);
nowPosition.add(Device(mac: "", x: X, y: Y));
return "${X.toStringAsFixed(2)} , ${Y.toStringAsFixed(2)} 與上點距離為${dist.toStringAsFixed(2)}";