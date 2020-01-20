package layers {
    import flash.geom.Point;
    import flash.utils.setTimeout;

    import global.Direction;

    import graph.Cell;


    public class Wind {
        public var points:Array;
        public var hexes:Array;

        private var grid:Array;

        public var start:WindHex;


        public function Wind(map:Map) {
            points = [];
            hexes = [];
            grid = [[]];

            var radius:Number = 50;
            var offset:Point = new Point(30, 30);
            var width:int = (map.width - 40) / (Math.sqrt(3) * radius);
            var height:int = (map.height - 40) / (radius * 2 * 0.75);

            for (var i:int = 0; i < width; i++) {
                grid [i] = [];
                for (var j:int = 0; j < height; j++) {
                    var w:Number = Math.sqrt(3) * radius;
                    var x:Number = i * w;
                    x += (w / 2) * (j % 2);
                    var y:Number = j * (2 * radius * 0.75);

                    var p:Point = new Point(offset.x + x,
                            offset.y + y);
                    var hex:WindHex = new WindHex(p,
                            radius);

                    points.push(p);
                    hexes.push(hex);
                    grid[i][j] = hex;
                }
            }

            for (i = 0; i < width; i++) {
                for (j = 0; j < height; j++) {
                    var h:WindHex = grid[i][j];
                    var odd:Boolean = j % 2 == 1;

                    // E
                    x = i + 1;
                    y = j;
                    if (x >= grid.length)
                        x = 0;
                    h.setNeighbor(grid[x][y], 0);

                    // W
                    x = i - 1;
                    y = j;
                    if (x < 0)
                        x = grid.length - 1;
                    h.setNeighbor(grid[x][y], 180);

                    // NE
                    x = odd ? i + 1 : i;
                    y = j - 1;
                    if (x >= grid.length)
                        x = 0;
                    if (y >= 0)
                        h.setNeighbor(grid[x][y], 300);

                    // NW
                    x = odd ? i : i - 1;
                    y = j - 1;
                    if (x < 0)
                        x = grid.length - 1;
                    if (y >= 0)
                        h.setNeighbor(grid[x][y], 240);

                    // SE
                    x = odd ? i + 1 : i;
                    y = j + 1;
                    if (x >= grid.length)
                        x = 0;
                    if (y < grid[x].length)
                        h.setNeighbor(grid[x][y], 60);

                    // SW
                    x = odd ? i : i - 1;
                    y = j + 1;
                    if (x < 0)
                        x = grid.length - 1;
                    if (y < grid[x].length)
                        h.setNeighbor(grid[x][y], 120);
                }
            }

            for each (h in hexes) {
                var averageHeight:Number = 0;
                var quadPoints:Array = map.quadTree.queryFromPoint(h.point, radius);
                var ocean:Boolean = false;
                for each (p in quadPoints) {
                    var cell:Cell = map.getCellByPoint(p);
                    averageHeight += cell.height;
                    if (cell.ocean)
                        ocean = true;
                }

                if (ocean)
                    h.height = map.seaLevel;
                else {
                    averageHeight /= quadPoints.length;
                    h.height = averageHeight >= 0 ? averageHeight : -1;
                }
            }

            // Smoothing for hexes that don't have any points under them
            for each (h in hexes) {
                if (h.height < 0) {
                    h.height = 0;
                    i = 0;
                    for each (var n:WindHex in h.neighbors)
                        if (n.height >= 0) {
                            h.height += n.height;
                            i++;
                        }
                    h.height /= i;
                }
            }

            applyInitialWinds();
        }

        public function reset():void {
            for each (var h:WindHex in hexes)
                h.reset();
        }

        private function applyInitialWinds():void {
            /**
             * Apply Initial Winds
             */

            var queue:Array = [];

            for (var i:int = 0; i < grid.length; i++) {
                for (var j:int = 0; j < grid[i].length; j++) {
                    var h:WindHex = grid[i][j];
                    // Default
                    h.angle = Direction.SOUTH;
                    h.strength = 0;

                    // North Polar Wind
                    if (j == 0) {
                        queue.push(h);
                        h.angle = Direction.SOUTH;
                        h.strength = 30;
                    }

                    // South Polar Wind
//                    if (j == grid[i].length - 1) {
//                        queue.push(h);
//                        h.angle = Direction.NORTH;
//                        h.strength = 20;
//                    }
                }
            }

//            propagate(queue);
        }

        public function propagate(queue:Array):void {
            /**
             * Propagate Wind
             */

            for each (var h:WindHex in hexes)
                h.used = false;

            var i:int = 0;
            if (queue.length > 0)
                setTimeout(pr, 250);

            function pr():void {
                h = queue.shift();
                h.index = i++;
                var targets:Array = h.propagate();

                for each (var target:WindHex in targets) {
                    var containsTarget:Boolean = false;
                    for each (h in queue) {
                        if (h == target) {
                            containsTarget = true;
                            break;
                        }
                    }
                    if (!containsTarget)
                        queue.push(target);
                }

                if (queue.length > 0)
                    setTimeout(pr, 250);
            }
        }

        public function closestHexToPoint(p:Point):WindHex {
            var closest:WindHex = hexes[0];
            for each (var h:WindHex in hexes) {
                if (Point.distance(h.point, p) < Point.distance(closest.point, p))
                    closest = h;
            }

            return closest;
        }

        public function hexFromPoint(p:Point):WindHex {
            for each (var h:WindHex in hexes) {
                if (h.point.equals(p)) {
                    return h;
                }
            }

            return null;
        }
    }
}
