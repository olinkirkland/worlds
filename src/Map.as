package {
    import com.nodename.delaunay.Voronoi;
    import com.nodename.geom.Segment;

    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;

    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import global.Color;

    import global.Global;

    import graph.*;

    import global.Rand;
    import global.Util;

    import layers.Lithosphere;
    import layers.TectonicPlate;
    import layers.Wind;


    public class Map {
        // Constants
        private const spacing:Number = 10;

        // Properties
        public var seed:int;
        public var width:int;
        public var height:int;

        // Model
        public var points:Vector.<Point>;
        public var cells:Vector.<Cell>;
        public var corners:Vector.<Corner>;
        public var edges:Vector.<Edge>;

        // Quadtree
        public var quadTree:QuadTree;
        public var bounds:Rectangle;

        // Controllers
        public var lithosphere:Lithosphere;
        public var wind:Wind;

        // Point Mapping
        private var cellsByPoints:Object;
        public var borderPoints:Array = [];

        // Wrapping
        public var leftWrapPoints:Array = [];
        public var rightWrapPoints:Array = [];
        private var leftWrapWidth:Number;

        // Properties
        public var seaLevel:Number = .35;


        public function Map(width:int,
                            height:int,
                            seed:int = 1) {
            this.width = width;
            this.height = height;
            this.seed = seed;

            bounds = new Rectangle(0,
                    0,
                    width,
                    height);

            Global.rand = new Rand(seed);

            makePoints();
            makeModel();

            lithosphere = new Lithosphere(this);

            addPerlinNoiseToHeightMap();
            smoothHeightMap();
            determineOcean();
            stretchHeightMap();
            setCornerHeights();

            this.width -= (leftWrapWidth - 2 * spacing);
            bounds.width = this.width;

            determineWind();
        }

        private function determineWind():void {
            var d:Date = new Date();
            Util.log("> Calculating wind...");
            wind = new Wind(this);

            Util.log("  " + Util.secondsSince(d));
        }

        private function determineOcean():void {
            var d:Date = new Date();
            Util.log("> Filling ocean with water...");

            // Determine biggest tectonic plate
            var biggestTectonicPlate:TectonicPlate;
            for each (var tectonicPlate:TectonicPlate in lithosphere.tectonicPlates)
                if (!biggestTectonicPlate || tectonicPlate.area > biggestTectonicPlate.area)
                    biggestTectonicPlate = tectonicPlate;

            // Find lowest cell on plate
            var lowestCell:Cell;
            for each (var cell:Cell in biggestTectonicPlate.cells)
                if (!lowestCell || cell.height < lowestCell.height)
                    lowestCell = cell;

            unuseCells();

            var queue:Vector.<Cell> = new Vector.<Cell>();
            cell = lowestCell;
            cell.used = true;
            queue.push(cell);
            while (queue.length > 0) {
                cell = queue.shift();
                cell.ocean = true;

                for each (var neighbor:Cell in cell.neighbors)
                    if (!neighbor.used && neighbor.height < seaLevel) {
                        neighbor.used = true;
                        queue.push(neighbor);
                    }
            }

            Util.log("  " + Util.secondsSince(d));
        }

        private function addPerlinNoiseToHeightMap():void {
            var d:Date = new Date();
            Util.log("> Adding Perlin noise to height map...");

            var bmpd:BitmapData = new BitmapData(width, height);
            var seed:uint = Global.rand.seed;
            bmpd.perlinNoise(bmpd.width, bmpd.height, 6, seed, true, false, BitmapDataChannel.GREEN, true);

            var i:int, j:int;

            var perlin:Array = [];
            for (i = 0; i < bmpd.width; i++) {
                perlin.push([]);
                for (j = 0; j < bmpd.height; j++)
                    perlin[i][j] = bmpd.getPixel(i, j);
            }

            var min:int = Number.POSITIVE_INFINITY;
            var max:int = Number.NEGATIVE_INFINITY;
            for (i = 0; i < perlin.length; i++) {
                for (j = 0; j < perlin[0].length; j++) {
                    var p:uint = perlin[i][j];
                    if (p < min) min = p;
                    if (p > max) max = p;
                }
            }

            max -= min;

            for (i = 0; i < perlin.length; i++) {
                for (j = 0; j < perlin[0].length; j++) {
                    perlin[i][j] -= min;
                    perlin[i][j] /= max;
                }
            }

            var perlinModifier:Number = .3;
            for each (var cell:Cell in cells)
                cell.height += (.5 - perlin[int(cell.point.x / width * perlin.length)][int(cell.point.y / height * perlin[0].length)]) * perlinModifier;

            Util.log("  " + Util.secondsSince(d));
        }

        private function smoothHeightMap():void {
            var d:Date = new Date();
            Util.log("> Smoothing height map...");

            // Limit cell heights
            for each (var cell:Cell in cells) {
                if (cell.height < 0)
                    cell.height = 0;
                if (cell.height > 1)
                    cell.height = 1;
            }

            for (var i:int = 0; i < 3; i++) {
                for each (cell in cells) {
                    var averageHeight:Number = 0;
                    for each (var neighbor:Cell in cell.neighbors)
                        averageHeight += neighbor.height;

                    for (var j:int = 0; j < (cell.tectonicPlateBorder ? 3 : 1); j++)
                        averageHeight += cell.height;


                    averageHeight /= cell.neighbors.length + j;
                    cell.height = averageHeight;
                }
            }

            Util.log("  " + Util.secondsSince(d));
        }

        private function stretchHeightMap():void {
            var d:Date = new Date();
            Util.log("> Stretching height...");

            var tallest:Number = Number.NEGATIVE_INFINITY;
            for each (var cell:Cell in cells)
                if (cell.height > tallest)
                    tallest = cell.height;
            for each (cell in cells)
                cell.height /= tallest;

            Util.log("  " + Util.secondsSince(d));
        }

        public function setCornerHeights():void {
            var d:Date = new Date();
            Util.log("> Assigning heights to corners...");

            for each (var corner:Corner in corners) {
                corner.height = 0;
                for each (var cell:Cell in corner.touches)
                    corner.height += cell.height;
                corner.height /= corner.touches.length;
            }

            Util.log("  " + Util.secondsSince(d));
        }

        public function unuseCells():void {
            for each(var cell:Cell in cells) {
                cell.used = false;
            }
        }


        public function nextUnusedCell():Cell {
            var i:int = 0;
            for each(var cell:Cell in cells) {
                i++;
                if (!cell.used) {
                    return cell;
                }
            }

            return null;
        }


        public function getCellByPoint(p:Point):Cell {
            return cellsByPoints[JSON.stringify(p)];
        }


        private function makeModel():void {
            // Setup
            var d:Date;

            d = new Date();
            Util.log("> Making Voronoi diagram...");
            var voronoi:Voronoi = new Voronoi(points,
                    bounds);

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
            Util.log("  " + Util.secondsSince(d));

            d = new Date();
            Util.log("> Making Voronoi regions...");
            for each (cell in cells) {
                voronoi.region(cell.point);
            }
            Util.log("  " + Util.secondsSince(d));

            /**
             * Associative Mapping
             */

            d = new Date();
            Util.log("> Making cell dictionary...");
            cellsByPoints = {};
            for each (cell in cells) {
                cellsByPoints[JSON.stringify(cell.point)] = cell;
            }

            Util.log("  " + Util.secondsSince(d));

            /**
             * Corners
             */

            var _cornerMap:Array = [];

            function makeCorner(point:Point):Corner {
                if (!point) {
                    return null;
                }
                for (var bucket:int = point.x - 1; bucket <= point.x + 1; bucket++) {
                    for each (var corner:Corner in _cornerMap[bucket]) {
                        var dx:Number = point.x - corner.point.x;
                        var dy:Number = point.y - corner.point.y;
                        if (dx * dx + dy * dy < 1e-6) {
                            return corner;
                        }
                    }
                }

                bucket = int(point.x);

                if (!_cornerMap[bucket]) {
                    _cornerMap[bucket] = [];
                }

                corner = new Corner();
                corner.index = corners.length;
                corners.push(corner);

                corner.point = point;
                corner.border = (point.x == 0 || point.x == bounds.width || point.y == 0 || point.y == bounds.height);

                _cornerMap[bucket].push(corner);
                return corner;
            }

            /**
             * Edges
             */

            d = new Date();
            Util.log("> Making edges...");
            var libEdges:Vector.<com.nodename.delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.delaunay.Edge in libEdges) {
                var dEdge:Segment = libEdge.delaunayLine();
                var vEdge:Segment = libEdge.voronoiEdge();

                var edge:Edge = new Edge();
                edge.index = edges.length;
                edges.push(edge);
                edge.midpoint = vEdge.p0 && vEdge.p1 && Point.interpolate(vEdge.p0,
                        vEdge.p1,
                        0.5);

                edge.v0 = makeCorner(vEdge.p0);
                edge.v1 = makeCorner(vEdge.p1);
                edge.d0 = cellsDictionary[dEdge.p0];
                edge.d1 = cellsDictionary[dEdge.p1];

                setupEdge(edge);
            }

            Util.log("  " + Util.secondsSince(d));

            /**
             * Clean Up and Wrap Borders
             */

            d = new Date();
            Util.log("> Wrapping borders...");
            for (var i:int = 0; i < cells.length; i++) {
                cell = cells[i];
                for each (var corner:Corner in cell.corners) {
                    if (corner.border) {
                        // Remove references
                        for each (var neighbor:Cell in cell.neighbors) {
                            for (var j:int = 0; j < neighbor.neighbors.length; j++) {
                                if (neighbor.neighbors[j] == cell) {
                                    neighbor.neighbors.removeAt(j--);
                                }
                            }
                        }

                        cell.neighbors = new Vector.<Cell>();
                        cell.corners = new Vector.<Corner>();
                        cell.edges = new Vector.<Edge>();
                        cells.removeAt(i--);
                        break;
                    }
                }

                var wrappedCell:Cell;

                // Right wrap
                var wrapIndex:int = rightWrapPoints.indexOf(cell.point);
                if (wrapIndex >= 0) {
                    wrappedCell = getCellByPoint(leftWrapPoints[wrapIndex]);
                    for each (neighbor in cell.neighbors) {
                        for (j = 0; j < neighbor.neighbors.length; j++) {
                            var n:Cell = neighbor.neighbors[j];
                            if (n == cell) {
                                neighbor.neighbors[j] = wrappedCell;
                            }
                        }
                    }

                    cell.neighbors = wrappedCell.neighbors = wrappedCell.neighbors.concat(cell.neighbors);
                }
            }

            // Remove wrap cells
            while (rightWrapPoints.length > 0) {
                var r:Point = rightWrapPoints.pop();
                var c:Cell = getCellByPoint(r);
                for (i = 0; i < cells.length; i++) {
                    if (cells[i] == c) {
                        cells.removeAt(i);
                        break;
                    }
                }
            }

            Util.log("  " + Util.secondsSince(d));

            /**
             * Cell Area
             */

            d = new Date();
            Util.log("> Calculating cell areas...");
            for each (cell in cells)
                cell.calculateArea();

            Util.log("  " + Util.secondsSince(d));
        }


        private function setupEdge(edge:Edge):void {
            if (edge.d0 != null) {
                edge.d0.edges.push(edge);
            }

            if (edge.d1 != null) {
                edge.d1.edges.push(edge);
            }

            if (edge.v0 != null) {
                edge.v0.protrudes.push(edge);
            }

            if (edge.v1 != null) {
                edge.v1.protrudes.push(edge);
            }

            if (edge.d0 != null && edge.d1 != null) {
                addToCellList(edge.d0.neighbors,
                        edge.d1);
                addToCellList(edge.d1.neighbors,
                        edge.d0);
            }

            if (edge.v0 != null && edge.v1 != null) {
                addToCornerList(edge.v0.adjacent,
                        edge.v1);
                addToCornerList(edge.v1.adjacent,
                        edge.v0);
            }

            if (edge.d0 != null) {
                addToCornerList(edge.d0.corners,
                        edge.v0);
                addToCornerList(edge.d0.corners,
                        edge.v1);
            }

            if (edge.d1 != null) {
                addToCornerList(edge.d1.corners,
                        edge.v0);
                addToCornerList(edge.d1.corners,
                        edge.v1);
            }

            if (edge.v0 != null) {
                addToCellList(edge.v0.touches,
                        edge.d0);
                addToCellList(edge.v0.touches,
                        edge.d1);
            }

            if (edge.v1 != null) {
                addToCellList(edge.v1.touches,
                        edge.d0);
                addToCellList(edge.v1.touches,
                        edge.d1);
            }

            function addToCornerList(v:Vector.<Corner>,
                                     x:Corner):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }

            function addToCellList(v:Vector.<Cell>,
                                   x:Cell):void {
                if (x != null && v.indexOf(x) < 0) {
                    v.push(x);
                }
            }
        }


        public function makePoints():void {
            points = new Vector.<Point>();
            quadTree = new QuadTree(bounds);

            // Size of the left wrap
            leftWrapWidth = spacing * 6;

            var d:Date = new Date();
            Util.log("> Making border points...");
            makeBorderPoints(spacing);
            Util.log("  " + Util.secondsSince(d));


            d = new Date();
            Util.log("> Making wrap points...");
            // Create left wrap points
            makePointsInArea(new Rectangle(0,
                    0,
                    leftWrapWidth,
                    bounds.height),
                    spacing,
                    50);

            // Copy left wrap points to the right wrap
            for each (var p:Point in points) {
                if (borderPoints.indexOf(p) < 0) {
                    leftWrapPoints.push(p);
                    rightWrapPoints.push(new Point(p.x + bounds.width - leftWrapWidth - spacing,
                            p.y));
                }
            }
            Util.log("  " + Util.secondsSince(d));

            for each (p in rightWrapPoints) {
                addPoint(p);
            }

            d = new Date();
            Util.log("> Filling the area with points...");
            // Fill the rest of the area
            makePointsInArea(bounds,
                    spacing,
                    10);

            Util.log("  " + points.length + " points");
            Util.log("  " + Util.secondsSince(d));
        }


        private function makePointsInArea(area:Rectangle,
                                          m:Number,
                                          precision:int):void {
            // The active point queue
            var queue:Vector.<Point> = new Vector.<Point>();

            var point:Point = new Point(int(area.width / 2),
                    int(area.height / 2));
            var box:Rectangle = new Rectangle(0,
                    0,
                    2 * m,
                    2 * m);

            addPoint(point);
            queue.push(point);

            while (queue.length > 0) {
                point = queue[0];
                var candidate:Point = null;

                for (var i:int = 0; i < precision; i++) {
                    var angle:Number = Global.rand.next() * 2 * Math.PI;
                    var distance:int = Global.rand.between(m,
                            2 * m);

                    candidate = new Point();
                    candidate.x = int(point.x + distance * Math.cos(angle));
                    candidate.y = int(point.y + distance * Math.sin(angle));

                    if (!area.contains(candidate.x,
                            candidate.y)) {
                        candidate = null;
                    } else {
                        // Check point distance to nearby points
                        box.x = candidate.x - m;
                        box.y = candidate.y - m;
                        if (quadTree.query(box).length > 0) {
                            candidate = null;
                        } else {
                            break;
                        }
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
        }


        private function addPoint(p:Point):void {
            points.push(p);
            quadTree.insert(p);
        }


        private function makeBorderPoints(m:Number):void {
            var p:Point;

            // Make the border points
            // Top and Bottom
            p = new Point(m,
                    m);
            while (p.x < bounds.width) {
                borderPoints.push(p);
                addPoint(p);

                p = new Point(p.x,
                        bounds.height - m);
                borderPoints.push(p);
                addPoint(p);

                p = new Point(p.x + m,
                        m);
            }

            // Left and Right
            p = new Point(m,
                    2 * m);
            while (p.y < bounds.height - m) {
                borderPoints.push(p);
                addPoint(p);

                p = new Point(m,
                        p.y + m);
            }
        }
    }
}
