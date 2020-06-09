package {
    import com.nodename.delaunay.Voronoi;
    import com.nodename.geom.Segment;

    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import global.Rand;
    import global.Sort;
    import global.Util;

    import graph.*;

    import layers.geography.Hydrology;
    import layers.geography.River;
    import layers.tectonics.Lithosphere;
    import layers.tectonics.TectonicPlate;
    import layers.temperature.Temperature;
    import layers.wind.Wind;

    public class Map {
        // Constants
        private const spacing:Number = 10;

        // World Properties
        public static var SEA_LEVEL:Number = .35;

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
        public var temperature:Temperature;
        public var wind:Wind;
        public var hydrology:Hydrology;

        // Point Mapping
        private var cellsByPoints:Object;
        public var borderPoints:Array = [];

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

            Rand.rand = new Rand(seed);

            makePoints();
            makeModel();

            lithosphere = new Lithosphere(this);

            addPerlinNoiseToHeightMap();
            smoothHeightMap();

            bounds.width = this.width;

            update();
        }

        public function update():void {
            determineOcean();
            stretchHeightMap();
            setCornerHeights();

            //determineTemperature();
            //determineWind();
            //determineHydrology();
            //determineRivers();
        }

        private function determineRivers():void {
            // Setup
            for each (var cell:Cell in cells) {
                cell.rivers = new Vector.<River>();
                cell.flux = cell.precipitation;
            }

            // Pour flux to lowest neighbors and determine rivers
            cells.sort(Sort.cellByAltitude).reverse();
            for each (cell in cells) {
                var lowestAltitude:Number = cell.altitude;
                for each (var neighbor:Cell in cell.neighbors) {
                    // The spacing * 2 is to avoid duplicate neighbors (due to wrapping)
                    if (neighbor.altitude < lowestAltitude && Util.distanceBetweenTwoPoints(cell.point, neighbor.point) < spacing * 2) {
                        lowestAltitude = neighbor.altitude;
                        cell.lowestNeighbor = neighbor;
                    }
                }

                if (cell.lowestNeighbor)
                    pour(cell, cell.lowestNeighbor);
            }
        }

        private function pour(cell:Cell, neighbor:Cell):void {
            if (cell.ocean) return;

            neighbor.flux += cell.flux;
            if (cell.flux > 1) {
                var river:River;
                if (cell.rivers.length > 0) {
                    // Extend the longest river that's already in this cell
                    for each (var r:River in cell.rivers) {
                        if (!river || r.cells.length > river.cells.length)
                            river = r;
                    }

                    river.addCell(neighbor);
                } else {
                    // Start new river
                    river = hydrology.addRiver();
                    river.addCell(cell);
                    river.addCell(neighbor);
                }

                // Identify points where the river empties into a body of water
                if (neighbor.ocean || !neighbor.lowestNeighbor) {
                    river.end = neighbor;
                }
            }
        }

        private function determineTemperature():void {
            var d:Date = new Date();
            Util.log("> Calculating temperature...");
            temperature = new Temperature(this);

            Util.log("  " + Util.secondsSince(d));
        }

        private function determineWind():void {
            var d:Date = new Date();
            Util.log("> Calculating wind...");
            wind = new Wind(this);

            Util.log("  " + Util.secondsSince(d));
        }

        private function determineHydrology():void {
            var d:Date = new Date();
            Util.log("> Calculating hydrology...");

            // Calculate hydrology
            hydrology = new Hydrology(this);

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
            var lowestCell:Cell = biggestTectonicPlate.cells[0];
            for each (var cell:Cell in biggestTectonicPlate.cells)
                if (cell.elevation < lowestCell.elevation)
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
                    if (!neighbor.used && neighbor.elevation < SEA_LEVEL) {
                        neighbor.used = true;
                        queue.push(neighbor);
                    }
            }

            Util.log("  " + Util.secondsSince(d));
        }

        private function addPerlinNoiseToHeightMap():void {
            var d:Date = new Date();
            Util.log("> Adding Perlin noise to elevation map...");

            var bmpd:BitmapData = new BitmapData(width, height);
            var seed:uint = Rand.rand.seed;
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
                cell.elevation += (.5 - perlin[int(cell.point.x / width * perlin.length)][int(cell.point.y / height * perlin[0].length)]) * perlinModifier;

            Util.log("  " + Util.secondsSince(d));
        }

        private function smoothHeightMap():void {
            var d:Date = new Date();
            Util.log("> Smoothing elevation map...");

            // Limit cell heights
            for each (var cell:Cell in cells) {
                cell.elevation = Math.min(1, cell.elevation);
                cell.elevation = Math.max(0, cell.elevation);
            }

            for (var i:int = 0; i < 3; i++) {
                for each (cell in cells) {
                    var average:Number = 0;
                    for each (var neighbor:Cell in cell.neighbors)
                        average += neighbor.elevation;

                    for (var j:int = 0; j < (cell.tectonicPlateBorder ? 3 : 1); j++)
                        average += cell.elevation;


                    average /= cell.neighbors.length + j;
                    cell.elevation = average;
                }
            }

            Util.log("  " + Util.secondsSince(d));
        }

        private function stretchHeightMap():void {
            var d:Date = new Date();
            Util.log("> Stretching elevation...");

            var tallest:Number = Number.NEGATIVE_INFINITY;
            for each (var cell:Cell in cells)
                if (cell.elevation > tallest)
                    tallest = cell.elevation;
            for each (cell in cells)
                cell.elevation /= tallest;

            Util.log("  " + Util.secondsSince(d));
        }

        public function setCornerHeights():void {
            var d:Date = new Date();
            Util.log("> Assigning heights to corners...");

            for each (var corner:Corner in corners) {
                corner.elevation = 0;
                for each (var cell:Cell in corner.touches)
                    corner.elevation += cell.elevation;
                corner.elevation /= corner.touches.length;
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

            var d:Date = new Date();
            Util.log("> Filling the area with points...");

            // Fill the rest of the area
            makePointsInArea(bounds,
                    15);

            Util.log("  " + points.length + " points");
            Util.log("  " + (points.length / ((new Date().time - d.time) / 1000)).toFixed(2) + " points/second");
            Util.log("  " + Util.secondsSince(d));
        }


        private function makePointsInArea(area:Rectangle,
                                          precision:int):void {
            // The active point queue
            var queue:Vector.<Point> = new Vector.<Point>();

            var point:Point = new Point(int(area.width / 2),
                    int(area.height / 2));

            var doubleSpacing:Number = spacing * 2;
            var doublePI:Number = 2 * Math.PI;

            var box:Rectangle = new Rectangle(0,
                    0,
                    2 * spacing,
                    2 * spacing);

            addPoint(point);
            queue.push(point);

            var candidate:Point = null;
            var angle:Number;
            var distance:int;

            while (queue.length > 0) {
                point = queue[0];

                for (var i:int = 0; i < precision; i++) {
                    angle = Rand.rand.next() * doublePI;
                    distance = Rand.rand.between(spacing, doubleSpacing);

                    candidate = new Point(point.x + distance * Math.cos(angle),
                            point.y + distance * Math.sin(angle));

                    // Check point distance to nearby points
                    box.x = candidate.x - spacing;
                    box.y = candidate.y - spacing;
                    if (quadTree.isRangePopulated(box)) {
                        candidate = null;
                    } else {
                        // Valid candidate
                        if (!area.contains(candidate.x, candidate.y)) {
                            // Candidate is outside the area, so don't include it
                            candidate = null;
                            continue;
                        }
                        break;
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
    }
}
