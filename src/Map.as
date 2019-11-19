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

        public function Map(width:int, height:int, pointCount:int) {
            var t:Date = new Date();
            var d:Date = new Date();
            trace("Choosing random points...")
            makePoints(width, height, pointCount);
            trace("Done in " + Util.secondsSince(d));
            bounds = new Rectangle(0, 0, width, height);

            d = new Date();
            trace("Making quadtree...");
            makeQuadTreeForPoints();
            trace("Done in " + Util.secondsSince(d));

            makeModel();
            trace("Total time taken: " + Util.secondsSince(t));
        }

        private function makeModel():void {
            // Setup
            var d:Date;

            d = new Date();
            trace("Making Voronoi diagram...");
            var voronoi:Voronoi = new Voronoi(points, bounds);
            trace("Done in " + Util.secondsSince(d));

            cells = new Vector.<Cell>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            /**
             * Cells
             */

            d = new Date();
            trace("  Making cell dictionary...");
            var cellDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points) {
                var cell:Cell = new Cell();
                cell.index = cells.length;
                cell.point = point;
                cells.push(cell);
                cellDictionary[point] = cell;
            }
            trace("  Done in " + Util.secondsSince(d));

            d = new Date();
            trace("  Making voronoi regions...")
            for each (cell in cells)
                voronoi.region(cell.point);
            trace("  Done in " + Util.secondsSince(d));

            /**
             * Corners
             */

            var _cornerMap:Array = [];

            function makeCorner(point:Point):Corner {
                var corner:Corner;

                if (point == null) return null;
                for (var bucket:int = int(point.x) - 1; bucket <= int(point.x) + 1; bucket++) {
                    for each (corner in _cornerMap[bucket]) {
                        var dx:Number = point.x - corner.point.x;
                        var dy:Number = point.y - corner.point.y;
                        if (dx * dx + dy * dy < 1e-6) {
                            return corner;
                        }
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
            trace("  Making edges...");
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
                edge.d0 = cellDictionary[dEdge.p0];
                edge.d1 = cellDictionary[dEdge.p1];

                setupEdge(edge);
            }
            trace("  Done in " + Util.secondsSince(d));
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

        private function makeQuadTreeForPoints():void {
            quadTree = new QuadTree(bounds);
            for each (var point:Point in points)
                quadTree.insert(point);
        }

        public function makePoints(width:int, height:int, pointCount:int):void {
            var m:int = 20;
            points = new Vector.<Point>();
            for (var i:int = 0; i < pointCount; i++) {
                var p:Point = new Point(m + Math.random() * (width - m * 2), m + Math.random() * (height - m * 2));
                points.push(p);
            }
        }
    }
}
