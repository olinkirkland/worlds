package {
    import com.nodename.delaunay.Voronoi;
    import com.nodename.geom.Segment;

    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import graph.*;

    public class Map {

        // Model
        public var points:Vector.<Point>;
        public var cells:Vector.<Cell>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;

        // Quadtree
        public var quadTree:QuadTree;
        private var bounds:Rectangle;

        // Associative Mapping
        private var cellsByPoints:Object;

        public function Map(width:int, height:int) {
            bounds = new Rectangle(0, 0, width, height);

            var t:Date = new Date();
            makePoints();
            makeModel();
            trace("Total time taken: " + Util.secondsSince(t));
        }

        private function makeModel():void {
            // Setup
            var d:Date;

            d = new Date();
            trace("Making Voronoi diagram...");
            var voronoi:Voronoi = new Voronoi(points, bounds);
            trace(Util.secondsSince(d));

            cells = new Vector.<Cell>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            /**
             * Cells
             */

            d = new Date();
            trace("Making cell dictionary...");
            var cellsDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points) {
                var cell:Cell = new Cell();
                cell.index = cells.length;
                cell.point = point;
                cells.push(cell);
                cellsDictionary[point] = cell;
            }
            trace(Util.secondsSince(d));

            d = new Date();
            trace("Making voronoi regions...")
            for each (cell in cells)
                voronoi.region(cell.point);
            trace(Util.secondsSince(d));

            /**
             * Corners
             */

            var _cornerMap:Array = [];

            function makeCorner(point:Point):Corner {
                if (!point)
                    return null;
                for (var bucket:int = point.x - 1; bucket <= point.x + 1; bucket++) {
                    for each (var corner:Corner in _cornerMap[bucket]) {
                        var dx:Number = point.x - corner.point.x;
                        var dy:Number = point.y - corner.point.y;
                        if (dx * dx + dy * dy < 1e-6)
                            return corner;
                    }
                }

                bucket = int(point.x);

                if (!_cornerMap[bucket]) _cornerMap[bucket] = [];

                corner = new Corner();
                corner.index = corners.length;
                corners.push(corner);

                corner.point = point;
                corner.border = (point.x == 0 || point.x == bounds.width
                        || point.y == 0 || point.y == bounds.height);

                _cornerMap[bucket].push(corner);
                return corner;
            }

            /**
             * Edges
             */

            d = new Date();
            trace("Making edges...");
            var libEdges:Vector.<com.nodename.delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.delaunay.Edge in libEdges) {
                var dEdge:Segment = libEdge.delaunayLine();
                var vEdge:Segment = libEdge.voronoiEdge();

                var edge:Edge = new Edge();
                edge.index = edges.length;
                edges.push(edge);
                edge.midpoint = vEdge.p0 && vEdge.p1 && Point.interpolate(vEdge.p0, vEdge.p1, 0.5);

                edge.v0 = makeCorner(vEdge.p0);
                edge.v1 = makeCorner(vEdge.p1);
                edge.d0 = cellsDictionary[dEdge.p0];
                edge.d1 = cellsDictionary[dEdge.p1];

                setupEdge(edge);
            }

            trace(Util.secondsSince(d));

            /**
             * Clean Up Borders
             */

            d = new Date();
            trace("Cleaning borders...");
            for (var i:int = 0; i < cells.length; i++) {
                cell = cells[i];
                for each (var corner:Corner in cell.corners) {
                    if (corner.border) {
                        // Remove references
                        for each (var neighbor:Cell in cell.neighbors) {
                            for (var j:int = 0; j < neighbor.neighbors.length; j++)
                                if (neighbor.neighbors[j] == cell) {
                                    neighbor.neighbors.removeAt(j--);
                                }
                        }

                        cell.neighbors = new Vector.<Cell>();
                        cell.corners = new Vector.<Corner>();
                        cell.edges = new Vector.<Edge>();
                        cells.removeAt(i--);
                        break;
                    }
                }
            }

            trace(Util.secondsSince(d));

            /**
             * Associative Mapping
             */

            d = new Date();
            trace("Preparing up associative mapping...");
            cellsByPoints = {};
            for each (cell in cells)
                cellsByPoints[JSON.stringify(cell.point)] = cell;

            trace(Util.secondsSince(d));
        }

        public function getCellByPoint(p:Point):Cell {
            return cellsByPoints[JSON.stringify(p)];
        }

        private function setupEdge(edge:Edge):void {
            if (edge.d0 != null)
                edge.d0.edges.push(edge);

            if (edge.d1 != null)
                edge.d1.edges.push(edge);

            if (edge.v0 != null)
                edge.v0.protrudes.push(edge);

            if (edge.v1 != null)
                edge.v1.protrudes.push(edge);

            if (edge.d0 != null && edge.d1 != null) {
                addToCellList(edge.d0.neighbors, edge.d1);
                addToCellList(edge.d1.neighbors, edge.d0);
            }

            if (edge.v0 != null && edge.v1 != null) {
                addToCornerList(edge.v0.adjacent, edge.v1);
                addToCornerList(edge.v1.adjacent, edge.v0);
            }

            if (edge.d0 != null) {
                addToCornerList(edge.d0.corners, edge.v0);
                addToCornerList(edge.d0.corners, edge.v1);
            }

            if (edge.d1 != null) {
                addToCornerList(edge.d1.corners, edge.v0);
                addToCornerList(edge.d1.corners, edge.v1);
            }

            if (edge.v0 != null) {
                addToCellList(edge.v0.touches, edge.d0);
                addToCellList(edge.v0.touches, edge.d1);
            }

            if (edge.v1 != null) {
                addToCellList(edge.v1.touches, edge.d0);
                addToCellList(edge.v1.touches, edge.d1);
            }

            function addToCornerList(v:Vector.<Corner>, x:Corner):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }

            function addToCellList(v:Vector.<Cell>, x:Cell):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }
        }

        public function makePoints():void {
            var d:Date = new Date();
            trace("Choosing random points...")

            points = new Vector.<Point>();
            quadTree = new QuadTree(bounds);

            // The active point queue
            var queue:Vector.<Point> = new Vector.<Point>();

            // The minimum distance between each point
            var m:Number = 20;

            var point:Point = new Point(int(Math.random() * bounds.width), int(Math.random() * bounds.height));
            queue.push(point);
            points.push(point);
            quadTree.insert(point);

            while (queue.length > 0) {
                trace(queue.length);
                point = queue[0];
                var nextPoint:Point = null;
                for (var i:int = 0; i < 30; i++) {
                    var angle:int = Math.random() * 360;
                    var distance:int = m + (Math.random() * m);

                    var c:Point = new Point();
                    c.x = point.x + distance * Math.cos(angle);
                    c.y = point.y + distance * Math.sin(angle);

                    // Check point distance to nearby points
                    var nearbyPoints:Array = quadTree.query(new Rectangle(c.x - m, c.y - m, c.x + m, c.y + m));
                    if (!bounds.contains(c.x, c.y))
                        break;

                    for each (var p:Point in nearbyPoints) {
                        if (Point.distance(c, p) < m) {
                            nextPoint = c;
                            break;
                        }
                    }
                }

                if (nextPoint) {
                    queue.push(nextPoint);
                    points.push(nextPoint);
                    quadTree.insert(nextPoint);
                } else {
                    // Remove the first point in queue
                    queue.shift();
                }
            }

            trace(Util.secondsSince(d));
        }
    }
}
