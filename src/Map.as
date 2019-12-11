package {
    import com.nodename.delaunay.Voronoi;
    import com.nodename.geom.Segment;

    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import graph.*;

    import graph.QuadTree;

    import util.Rand;

    import util.Util;

    public class Map {

        public var rand:Rand = new Rand();

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

        public function Map(width:int, height:int, seed:int = 1) {
            bounds = new Rectangle(0, 0, width, height);
            rand = new Rand(seed);

            makePoints();
            makeModel();
        }

        public function unuseCells():void {
            for each(var cell:Cell in cells)
                cell.used = false;
        }

        public function nextUnusedCell():Cell {
            var i:int = 0;
            for each(var cell:Cell in cells) {
                i++;
                if (!cell.used)
                    return cell;
            }

            return null;
        }

        private function makeModel():void {
            // Setup
            var d:Date;

            d = new Date();
            Util.log("Making Voronoi diagram...");
            var voronoi:Voronoi = new Voronoi(points, bounds);

            cells = new Vector.<Cell>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            // Make cell dictionary
            var cellsDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points) {
                var cell:Cell = new Cell();
                cell.index = cells.length;
                cell.point = point;
                cells.push(cell);
                cellsDictionary[point] = cell;
            }
            Util.log(Util.secondsSince(d));

            d = new Date();
            Util.log("Making voronoi regions...");
            for each (cell in cells)
                voronoi.region(cell.point);
            Util.log(Util.secondsSince(d));

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
            Util.log("Making edges...");
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

            Util.log(Util.secondsSince(d));

            /**
             * Clean Up Borders
             */

            d = new Date();
            Util.log("Cleaning borders...");
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

            Util.log(Util.secondsSince(d));

            /**
             * Associative Mapping
             */

            d = new Date();
            Util.log("Setting up associative mapping...");
            cellsByPoints = {};
            for each (cell in cells)
                cellsByPoints[JSON.stringify(cell.point)] = cell;

            Util.log(Util.secondsSince(d));

            /**
             * Cell Area
             */

            d = new Date();
            Util.log("Calculating cell areas...");
            for each (cell in cells)
                cell.calculateArea();

            Util.log(Util.secondsSince(d));
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
            Util.log("Choosing points...");

            points = new Vector.<Point>();
            quadTree = new QuadTree(bounds);

            // The minimum distance between each point
            var m:Number = 10;

            // Create binding points (left and right)
            var bindingPoints:Array = [];
            var p:Point = new Point();

            // Left binding
            while (p.y < bounds.height - m) {
                p = new Point(5 * m, p.y + m);
                addPoint(p);
            }

            // Right binding
            p = new Point();
            while (p.y < bounds.height - m) {
                p = new Point(bounds.width - (5 * m), p.y + m);
                addPoint(p);
            }

            // The active point queue
            var queue:Vector.<Point> = new Vector.<Point>();

            var point:Point = new Point(int(bounds.width / 2), int(bounds.height / 2));
            var box:Rectangle = new Rectangle(0, 0, 2 * m, 2 * m);

            addPoint(point);
            queue.push(point);

            while (queue.length > 0) {
                point = queue[0];
                var candidate:Point = null;

                for (var i:int = 0; i < 5; i++) {
                    var angle:Number = rand.next() * 2 * Math.PI;
                    var distance:int = rand.between(m, 2 * m);

                    candidate = new Point();
                    candidate.x = int(point.x + distance * Math.cos(angle));
                    candidate.y = int(point.y + distance * Math.sin(angle));

                    if (!bounds.contains(candidate.x, candidate.y)) {
                        candidate = null;
                    } else {
                        // Check point distance to nearby points
                        box.x = candidate.x - m;
                        box.y = candidate.y - m;
                        if (quadTree.query(box).length > 0)
                            candidate = null;
                        else break;
                    }
                }

                if (candidate) {
                    addPoint(candidate);
                    queue.push(candidate);
                } else {
                    // Remove the first point in queue
                    queue.shift();
                }
            }

            Util.log(points.length + " points");

            Util.log(Util.secondsSince(d));

            function addPoint(p:Point):void {
                points.push(p);
                quadTree.insert(p);
            }
        }
    }
}
