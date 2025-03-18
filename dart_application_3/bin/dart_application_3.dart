import 'dart:math';
import 'dart:io';

// Константы
const int gridSize = 10;
const List<int> shipSizes = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];

// Типы ячеек игрового поля
enum CellState {
  empty,
  ship,
  miss,
  hit,
  sunk,
}

class Grid {
  List<List<CellState>> cells;

  Grid()
      : cells = List.generate(
            gridSize, (_) => List.filled(gridSize, CellState.empty));

  // Отображение игрового поля
  void display({bool showShips = false}) {
    print(
        '  ${List.generate(gridSize, (i) => String.fromCharCode('A'.codeUnitAt(0) + i)).join(' ')}');
    for (int row = 0; row < gridSize; row++) {
      stdout.write('${row + 1} ');
      for (int col = 0; col < gridSize; col++) {
        switch (cells[row][col]) {
          case CellState.empty:
            stdout.write('. ');
            break;
          case CellState.ship:
            stdout.write(showShips ? 'S ' : '. ');
            break;
          case CellState.miss:
            stdout.write('O ');
            break;
          case CellState.hit:
            stdout.write('X ');
            break;
          case CellState.sunk:
            stdout.write('* ');
            break;
        }
      }
      print('');
    }
  }

  // Проверка, находится ли ячейка в пределах поля
  bool isValidCoordinate(int row, int col) {
    return row >= 0 && row < gridSize && col >= 0 && col < gridSize;
  }

  // Проверка, можно ли разместить корабль в данной позиции
  bool canPlaceShip(int row, int col, int size, bool isHorizontal) {
    for (int i = 0; i < size; i++) {
      int currentRow = row + (isHorizontal ? 0 : i);
      int currentCol = col + (isHorizontal ? i : 0);

      if (!isValidCoordinate(currentRow, currentCol)) {
        return false;
      }

      // Проверяем, не занята ли ячейка или соседние ячейки
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          int checkRow = currentRow + dr;
          int checkCol = currentCol + dc;
          if (isValidCoordinate(checkRow, checkCol) &&
              cells[checkRow][checkCol] != CellState.empty) {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Размещение корабля на поле
  void placeShip(int row, int col, int size, bool isHorizontal) {
    for (int i = 0; i < size; i++) {
      int currentRow = row + (isHorizontal ? 0 : i);
      int currentCol = col + (isHorizontal ? i : 0);
      cells[currentRow][currentCol] = CellState.ship;
    }
  }
  // Обработка выстрела по ячейке
  CellState? handleShot(int row, int col) {
    if (!isValidCoordinate(row, col)) {
      return null; // Недопустимые координаты
    }

    if (cells[row][col] == CellState.miss ||
        cells[row][col] == CellState.hit ||
        cells[row][col] == CellState.sunk) {
      return null; // Уже стреляли
    }

    if (cells[row][col] == CellState.ship) {
      cells[row][col] = CellState.hit;

      // Проверяем, потоплен ли корабль
      if (isShipSunk(row, col)) {
        sinkShip(row, col);
        return CellState.sunk;
      }
      return CellState.hit;
    } else {
      cells[row][col] = CellState.miss;
      return CellState.miss;
    }
  }

  // Проверка, потоплен ли корабль после попадания
  bool isShipSunk(int row, int col) {
    // Находим начало корабля
    int startRow = row;
    int startCol = col;
    bool isHorizontal;

    // Ищем влево, пока не найдем край корабля или пустую ячейку
    while (isValidCoordinate(startRow, startCol - 1) &&
        (cells[startRow][startCol - 1] == CellState.ship ||
            cells[startRow][startCol - 1] == CellState.hit)) {
      startCol--;
    }

    // Ищем вверх, пока не найдем край корабля или пустую ячейку
    while (isValidCoordinate(startRow - 1, startCol) &&
        (cells[startRow - 1][startCol] == CellState.ship ||
            cells[startRow - 1][startCol] == CellState.hit)) {
      startRow--;
    }

    // Определяем ориентацию корабля
    if (isValidCoordinate(startRow, startCol + 1) &&
        (cells[startRow][startCol + 1] == CellState.ship ||
            cells[startRow][startCol + 1] == CellState.hit)) {
      isHorizontal = true;
    } else {
      isHorizontal = false;
    }

    // Определяем длину корабля
    int shipSize = 0;
    int currentRow = startRow;
    int currentCol = startCol;

    while (isValidCoordinate(currentRow, currentCol) &&
        (cells[currentRow][currentCol] == CellState.ship ||
            cells[currentRow][currentCol] == CellState.hit)) {
      shipSize++;
      if (isHorizontal) {
        currentCol++;
      } else {
        currentRow++;
      }
    }

    // Проверяем, все ли части корабля подбиты
    int hitCount = 0;
    currentRow = startRow;
    currentCol = startCol;

    for (int i = 0; i < shipSize; i++) {
      if (cells[currentRow][currentCol] == CellState.hit) {
        hitCount++;
      }
      if (isHorizontal) {
        currentCol++;
      } else {
        currentRow++;
      }
    }

    return hitCount == shipSize;
  }

  // Помечаем потопленный корабль как Sunk и окружаем его Miss
  void sinkShip(int row, int col) {
    // Находим начало корабля
    int startRow = row;
    int startCol = col;
    bool isHorizontal;

    // Ищем влево, пока не найдем край корабля или пустую ячейку
    while (isValidCoordinate(startRow, startCol - 1) &&
        (cells[startRow][startCol - 1] == CellState.hit)) {
      startCol--;
    }

    // Ищем вверх, пока не найдем край корабля или пустую ячейку
    while (isValidCoordinate(startRow - 1, startCol) &&
        (cells[startRow - 1][startCol] == CellState.hit)) {
      startRow--;
    }

    // Определяем ориентацию корабля
    if (isValidCoordinate(startRow, startCol + 1) &&
        (cells[startRow][startCol + 1] == CellState.hit ||
            cells[startRow][startCol + 1] == CellState.ship)) {
      isHorizontal = true;
    } else {
      isHorizontal = false;
    }

    // Определяем длину корабля
    int shipSize = 0;
    int currentRow = startRow;
    int currentCol = startCol;

    while (isValidCoordinate(currentRow, currentCol) &&
        (cells[currentRow][currentCol] == CellState.hit ||
            cells[currentRow][currentCol] == CellState.ship)) {
shipSize++;
      if (isHorizontal) {
        currentCol++;
      } else {
        currentRow++;
      }
    }

    // Помечаем как потопленный
    currentRow = startRow;
    currentCol = startCol;

    for (int i = 0; i < shipSize; i++) {
      cells[currentRow][currentCol] = CellState.sunk;
      if (isHorizontal) {
        currentCol++;
      } else {
        currentRow++;
      }
    }

    // Окружаем корабль промахами
    currentRow = startRow - 1;
    currentCol = startCol - 1;
    for (int i = 0; i < shipSize + 2; i++) {
      if (isValidCoordinate(currentRow, currentCol + i) &&
          cells[currentRow][currentCol + i] == CellState.empty) {
        cells[currentRow][currentCol + i] = CellState.miss;
      }
    }
    currentRow = startRow + 1;
    currentCol = startCol - 1;
    for (int i = 0; i < shipSize + 2; i++) {
      if (isValidCoordinate(currentRow, currentCol + i) &&
          cells[currentRow][currentCol + i] == CellState.empty) {
        cells[currentRow][currentCol + i] = CellState.miss;
      }
    }
    currentRow = startRow;
    currentCol = startCol - 1;
    if (isValidCoordinate(currentRow, currentCol) &&
        cells[currentRow][currentCol] == CellState.empty) {
      cells[currentRow][currentCol] = CellState.miss;
    }
    currentRow = startRow;
    currentCol = startCol + shipSize;
    if (isValidCoordinate(currentRow, currentCol) &&
        cells[currentRow][currentCol] == CellState.empty) {
      cells[currentRow][currentCol] = CellState.miss;
    }
  }

  // Проверка, остались ли еще корабли на поле
  bool areAllShipsSunk() {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (cells[row][col] == CellState.ship) {
          return false;
        }
      }
    }
    return true;
  }

  // Подсчет количества живых кораблей
  int countRemainingShips() {
    int count = 0;
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (cells[row][col] == CellState.ship) {
          count++;
        }
      }
    }
    return count;
  }
}

// Функция для автоматической расстановки кораблей компьютером
void placeShipsRandomly(Grid grid) {
  final random = Random();
  for (int shipSize in shipSizes) {
    bool placed = false;
    while (!placed) {
      int row = random.nextInt(gridSize);
      int col = random.nextInt(gridSize);
      bool isHorizontal = random.nextBool();

      if (grid.canPlaceShip(row, col, shipSize, isHorizontal)) {
        grid.placeShip(row, col, shipSize, isHorizontal);
        placed = true;
      }
    }
  }
}

// Функция для получения координат выстрела от игрока
(int, int)? getPlayerShot() {
  print('Введите координаты выстрела (например, A1):');
  String? input = stdin.readLineSync();

  if (input == null || input.isEmpty) {
    return null;
  }

  input = input.toUpperCase();

  if (input.length < 2) {
    print('Некорректный формат координат.');
    return null;
  }

  int col = input.codeUnitAt(0) - 'A'.codeUnitAt(0);
  int? row = int.tryParse(input.substring(1)) != null
      ? int.parse(input.substring(1)) - 1
      : null;

  if (col < 0 ||
      col >= gridSize ||
      row == null ||
      row < 0 ||
      row >= gridSize) {
    print('Некорректные координаты.');
    return null;
  }

  return (row, col);
}

// Функция для получения координат корабля от игрока
(int, int, bool)? getPlayerShipPlacement(int shipSize) {
  print(
      'Введите координаты и ориентацию для корабля размером $shipSize (например, A1 H):');
  String? input = stdin.readLineSync();

  if (input == null || input.isEmpty) {
    return null;
  }

  input = input.toUpperCase();
  List<String> parts = input.split(' ');

  if (parts.length != 2) {
    print('Некорректный формат ввода.');
    return null;
  }

  if (parts[0].length < 2) {
    print('Некорректный формат координат.');
    return null;
  }

  int col = parts[0].codeUnitAt(0) - 'A'.codeUnitAt(0);
  int? row = int.tryParse(parts[0].substring(1)) != null
      ? int.parse(parts[0].substring(1)) - 1
      : null;
  bool isHorizontal;

  if (parts[1] == 'H') {
    isHorizontal = true;
  } else if (parts[1] == 'V') {
    isHorizontal = false;
  } else {
    print('Некорректная ориентация. Используйте H (горизонтально) или V (вертикально).');
    return null;
  }

  if (col < 0 ||
      col >= gridSize ||
      row == null ||
      row < 0 ||
      row >= gridSize) {
    print('Некорректные координаты.');
    return null;
  }

  return (row, col, isHorizontal);
}

// Функция для ручной расстановки кораблей игроком
void placeShipsManually(Grid grid) {
  grid.display();
  for (int shipSize in shipSizes) {
    bool placed = false;
    while (!placed) {
      (int, int, bool)? placement = getPlayerShipPlacement(shipSize);

      if (placement == null) {
        print('Некорректный ввод. Попробуйте еще раз.');
        continue;
      }

      int row = placement.$1;
      int col = placement.$2;
      bool isHorizontal = placement.$3;

      if (grid.canPlaceShip(row, col, shipSize, isHorizontal)) {
        grid.placeShip(row, col, shipSize, isHorizontal);
        grid.display();
        placed = true;
      } else {
        print('Невозможно разместить корабль в этом месте. Попробуйте еще раз.');
      }
    }
  }
}

// Класс для хранения статистики игры
class GameStats {
  int playerShipsLost = 0;
  int computerShipsLost = 0;
  int playerTotalShots = 0;
  int playerHits = 0;
  int playerMisses = 0;
  int computerTotalShots = 0;
  int computerHits = 0;
  int computerMisses = 0;
  int playerRemainingShips = shipSizes.length;
  int computerRemainingShips = shipSizes.length;

  // Метод для обновления статистики после выстрела игрока
  void updatePlayerShotStats(CellState? result) {
    playerTotalShots++;
    if (result == CellState.hit || result == CellState.sunk) {
      playerHits++;
    } else {
      playerMisses++;
    }
  }

  // Метод для обновления статистики после выстрела компьютера
  void updateComputerShotStats(CellState? result) {
    computerTotalShots++;
    if (result == CellState.hit || result == CellState.sunk) {
      computerHits++;
    } else {
      computerMisses++;
    }
  }

  // Метод для сохранения статистики в файл
  void saveStatsToFile(String fileName) {
    final directory = Directory('game_stats'); // Создаем каталог
    if (!directory.existsSync()) {
      directory.createSync();
    }
    final file = File('${directory.path}/$fileName');
    file.writeAsStringSync('''
      Game Statistics:
      ----------------
      Player:
        Ships Lost: $playerShipsLost
        Total Shots: $playerTotalShots
        Hits: $playerHits
        Misses: $playerMisses
        Remaining Ships: $playerRemainingShips
      
      Computer:
        Ships Lost: $computerShipsLost
        Total Shots: $computerTotalShots
        Hits: $computerHits
        Misses: $computerMisses
        Remaining Ships: $computerRemainingShips
    ''');
    print('Статистика игры сохранена в файл: ${file.path}');
  }
}

void main() {
  final playerGrid = Grid();
  final computerGrid = Grid();
  final gameStats = GameStats(); // Создаем экземпляр класса GameStats

  // Расстановка кораблей компьютером
  placeShipsRandomly(computerGrid);

  // Расстановка кораблей игроком вручную
  print('Расставьте свои корабли.');
  placeShipsManually(playerGrid);

  // Основной игровой цикл
  bool playerTurn = true;
  int playerScore = 0;
  int computerScore = 0;

  while (!playerGrid.areAllShipsSunk() && !computerGrid.areAllShipsSunk()) {
    print('---------------------');
    print('Ваш ход:');

    if (playerTurn) {
      computerGrid.display();
      (int, int)? shotCoordinates = getPlayerShot();

      if (shotCoordinates == null) {
        print('Некорректный ввод. Попробуйте еще раз.');
        continue;
      }

      int row = shotCoordinates.$1;
      int col = shotCoordinates.$2;

      CellState? result = computerGrid.handleShot(row, col);
      gameStats.updatePlayerShotStats(result); // Обновляем статистику игрока

      if (result == null) {
        print('Вы уже стреляли в эту клетку. Попробуйте еще раз.');
        continue;
      }

      if (result == CellState.hit) {
        print('Попадание!');
        playerScore++;
      } else if (result == CellState.miss) {
        print('Промах.');
      } else if (result == CellState.sunk) {
        print('Потопил!');
        playerScore++;
        gameStats.computerShipsLost++; // Увеличиваем кол-во потопленных кораблей компьютера
        gameStats.computerRemainingShips = computerGrid.countRemainingShips();
      }

      if (result != CellState.hit && result != CellState.sunk) {
        playerTurn = false;
      }
    } else {
      print('Ход компьютера:');
      final random = Random();
      int row, col;
      CellState? result;

      do {
        row = random.nextInt(gridSize);
        col = random.nextInt(gridSize);
        result = playerGrid.handleShot(row, col);
      } while (result == null);

      gameStats.updateComputerShotStats(result); // Обновляем статистику компьютера

      if (result == CellState.hit) {
        print('Компьютер попал!');
        computerScore++;
      } else if (result == CellState.miss) {
        print('Компьютер промахнулся.');
      } else if (result == CellState.sunk) {
        print('Компьютер потопил ваш корабль!');
        computerScore++;
        gameStats.playerShipsLost++; // Увеличиваем кол-во потопленных кораблей игрока
        gameStats.playerRemainingShips = playerGrid.countRemainingShips();
      }

      playerGrid.display();

      playerTurn = true;
    }

    print('Счет: Вы - $playerScore, Компьютер - $computerScore');
  }

  // Определение победителя
  print('---------------------');
  if (playerGrid.areAllShipsSunk()) {
    print('Компьютер победил!');
  } else {
    print('Вы победили!');
  }

  // Сохранение статистики в файл
  gameStats.saveStatsToFile('game_stats_${DateTime.now().millisecondsSinceEpoch}.txt');
}