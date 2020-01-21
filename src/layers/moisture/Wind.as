package layers.moisture {
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.setTimeout;

    import global.Direction;

    import graph.Cell;


    public class Wind {
        public var points:Array;

        private var grid:Array;
        public var gusts:Array;


        public function Wind(map:Map) {
            points = [];
            grid = [[]];
            gusts = [];

            var size:Number = 10;
            var offset:Point = new Point(20, 20);
            var width:int = map.width - 40;
            var height:int = map.height - 40;

            var gust:Gust;
            for (var i:int = 0; i < width / size; i++) {
                grid [i] = [];
                for (var j:int = 0; j < height / size; j++) {
                    var p:Point = new Point(i * size + offset.x, j * size + offset.y);
                    gust = new Gust(p,
                            size);

                    points.push(p);
                    gusts.push(gust);
                    grid[i][j] = gust;
                }
            }

            // Set neighbors
            for (i = 0; i < grid.length; i++) {
                for (j = 0; j < grid[i].length; j++) {
                    gust = grid[i][j];

                    // North
                    if (i > 0)
                        gust.setNeighbor(grid[i - 1][j], Direction.WEST);

                    // East
                    if (j < grid[i].length - 1)
                        gust.setNeighbor(grid[i][j + 1], Direction.SOUTH);

                    // South
                    if (i < grid.length - 1)
                        gust.setNeighbor(grid[i + 1][j], Direction.EAST);

                    // West
                    if (j > 0)
                        gust.setNeighbor(grid[i][j - 1], Direction.NORTH);
                }
            }

            for each (gust in gusts) {
                var averageHeight:Number = 0;
                var quadPoints:Array = map.quadTree.query(new Rectangle(gust.point.x, gust.point.y, size, size));

                var ocean:Boolean = false;
                for each (p in quadPoints) {
                    var cell:Cell = map.getCellByPoint(p);
                    averageHeight += cell.height;
                    if (cell.ocean)
                        ocean = true;
                }

                if (ocean) {
                    gust.ocean = true;
                    gust.height = map.seaLevel;
                }
                else {
                    averageHeight /= quadPoints.length;
                    gust.height = averageHeight >= 0 ? averageHeight : -1;
                }
            }

            // Smoothing for gusts that don't have any points under them
            for each (gust in gusts) {
                if (gust.height < 0) {
                    gust.height = 0;
                    i = 0;
                    for each (var neighbor:Gust in gust.neighbors)
                        if (neighbor && neighbor.height >= 0) {
                            gust.height += neighbor.height;
                            i++;
                        }
                    gust.height /= i;
                }
            }

            applyInitialWinds();
        }

        public function reset():void {
            for each (var h:Gust in gusts)
                h.reset();
        }

        private function applyInitialWinds():void {
            /**
             * Apply Initial Winds
             */

            var queue:Array = [];

            for (var i:int = 0; i < grid.length; i++) {
                for (var j:int = 0; j < grid[i].length; j++) {
                    var gust:Gust = grid[i][j];
                    // Default
                    gust.angle = Direction.SOUTH;
                    gust.strength = 0;

                    // North Polar Wind
                    if (j == 0) {
                        queue.push(gust);
                        gust.angle = Direction.SOUTH;
                        gust.strength = 20;
                    }

                    // South Polar Wind
                    if (j == grid[i].length - 1) {
                        queue.push(gust);
                        gust.angle = Direction.NORTH;
                        gust.strength = 20;
                    }
                }
            }

            propagate(queue);
        }

        public function propagate(queue:Array):void {
            /**
             * Propagate Wind
             */

            for each (var gust:Gust in gusts)
                gust.used = false;

            pr();

            function pr():void {
                gust = queue.shift();
                var targets:Array = gust.sendForce();

                for each (var target:Gust in targets) {
                    var containsTarget:Boolean = false;
                    for each (gust in queue) {
                        if (gust == target) {
                            containsTarget = true;
                            break;
                        }
                    }
                    if (!containsTarget)
                        queue.push(target);
                }

                if (queue.length > 0)
                    pr();
            }
        }

        public function closestGustToPoint(p:Point):Gust {
            var closest:Gust = gusts[0];
            for each (var h:Gust in gusts) {
                if (Point.distance(h.point, p) < Point.distance(closest.point, p))
                    closest = h;
            }

            return closest;
        }

        public function gustFromPoint(p:Point):Gust {
            for each (var h:Gust in gusts) {
                if (h.point.equals(p)) {
                    return h;
                }
            }

            return null;
        }
    }
}
