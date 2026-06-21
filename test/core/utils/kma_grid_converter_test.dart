import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/core/utils/kma_grid_converter.dart';

void main() {
  test('서울시청 좌표 → 기상청 표준 격자 (60, 127)', () {
    final grid = latLonToGrid(37.5665, 126.9780);
    expect(grid.nx, 60);
    expect(grid.ny, 127);
  });

  test('부산시청 좌표 → 격자 (98, 76)', () {
    final grid = latLonToGrid(35.1796, 129.0756);
    expect(grid.nx, 98);
    expect(grid.ny, 76);
  });

  test('제주시청 좌표 → 격자 (53, 38)', () {
    final grid = latLonToGrid(33.4996, 126.5312);
    expect(grid.nx, 53);
    expect(grid.ny, 38);
  });
}
