package
{
    import com.nodename.delaunay.Voronoi;
    import com.nodename.geom.Segment;

    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Dictionary;

    import global.Rand;
    import global.Util;
    import global.performance.PerformanceReport;
    import global.performance.PerformanceReportItem;

    import graph.*;

    import layers.geography.climate.Climate;
    import layers.geography.hydrology.Hydrology;
    import layers.tectonics.Lithosphere;
    import layers.tectonics.TectonicPlate;
    import layers.wind.Wind;

    import ui.Settings;

    public class Map
    {
        // Map Properties
        public static var seaLevel:Number = .35;

        // Constants
        private var spacing:Number = 8;
        private var precision:Number = 5;
        private var smoothPasses:int = 5;

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
        public var climate:Climate;
        public var hydrology:Hydrology;

        // Point Mapping
        private var cellsByPoints:Object;

        public function Map(width:int,
                            height:int,
                            seed:int = 1)
        {
            // Set defaultProperties
            spacing = Settings.properties.spacing;
            precision = Settings.properties.precision;
            smoothPasses = Settings.properties.smoothing;
            seaLevel = Settings.properties.seaLevel;

            this.width = width;
            this.height = height;
            this.seed = seed;

            bounds = new Rectangle(0,
                    0,
                    width,
                    height);

            Rand.rand = new Rand(seed);

            PerformanceReport.reset();

            makePoints();
            makeModel();

            lithosphere = new Lithosphere(this);

            addPerlinNoiseToHeightMap();
            smoothHeightMap();

            bounds.width = this.width;

            stretchHeightMap();
            determineOceans();
            setCornerHeights();

            determineWindAndMoisture();

            determineClimate();
        }

        private function determineWindAndMoisture():void
        {
            var d:Date = new Date();
            wind = new Wind(this);
            hydrology = new Hydrology(this);

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Wind and moisture", Util.secondsSince(d)));
        }

        private function determineClimate():void
        {
            var d:Date = new Date();
            climate = new Climate(this);

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Climate and biomes", Util.secondsSince(d)));
        }

        private function determineOceans():void
        {
            var d:Date = new Date();

            unuseCells();

            // The ocean fills from the six deep plates (3 left, 3 right)
            // Get deep plates (left and right deep oceans)
            var deepPlates:Array = [];
            for each (var t:TectonicPlate in lithosphere.tectonicPlates)
                if (t.type == TectonicPlate.DEEP)
                    deepPlates.push(t);

            var queue:Vector.<Cell> = new Vector.<Cell>();
            for each (t in deepPlates)
                queue.push(t.cells[0]);

            while (queue.length > 0)
            {
                var cell:Cell = queue.shift();
                cell.used = true;
                cell.ocean = true;

                for each (var neighbor:Cell in cell.neighbors)
                    if (!neighbor.used && neighbor.elevation < seaLevel)
                    {
                        neighbor.used = true;
                        queue.push(neighbor);
                    }
            }

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Ocean", Util.secondsSince(d)));
        }

        private function addPerlinNoiseToHeightMap():void
        {
            var d:Date = new Date();

            var bmpd:BitmapData = new BitmapData(width, height);
            var seed:uint = Rand.rand.seed;
            bmpd.perlinNoise(bmpd.width, bmpd.height, 6, seed, true, false, BitmapDataChannel.GREEN, true);

            var i:int, j:int;

            var perlin:Array = [];
            for (i = 0; i < bmpd.width; i++)
            {
                perlin.push([]);
                for (j = 0; j < bmpd.height; j++)
                    perlin[i][j] = bmpd.getPixel(i, j);
            }

            var min:int = Number.POSITIVE_INFINITY;
            var max:int = Number.NEGATIVE_INFINITY;
            for (i = 0; i < perlin.length; i++)
            {
                for (j = 0; j < perlin[0].length; j++)
                {
                    var p:uint = perlin[i][j];
                    if (p < min) min = p;
                    if (p > max) max = p;
                }
            }

            max -= min;

            for (i = 0; i < perlin.length; i++)
            {
                for (j = 0; j < perlin[0].length; j++)
                {
                    perlin[i][j] -= min;
                    perlin[i][j] /= max;
                }
            }

            var perlinModifier:Number = .8;
            for each (var cell:Cell in cells)
                cell.elevation += (.5 - perlin[int(cell.point.x / width * perlin.length)][int(cell.point.y / height * perlin[0].length)]) * perlinModifier;

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Perlin noise", Util.secondsSince(d)));
        }

        private function smoothHeightMap():void
        {
            var d:Date = new Date();

            // Limit cell heights
            for each (var cell:Cell in cells)
            {
                cell.elevation = Math.min(1, cell.elevation);
                cell.elevation = Math.max(0, cell.elevation);
            }

            for (var i:int = 0; i < smoothPasses; i++)
            {
                for each (cell in cells)
                {
                    var average:Number = 0;
                    var neighborCount:Number = 0;
                    for each (var neighbor:Cell in cell.neighbors)
//                        if (cell.tectonicPlate.type != TectonicPlate.DEEP)
                    {
                        neighborCount++;
                        average += neighbor.elevation;
                    }

                    for (var j:int = 0; j < (cell.tectonicPlateBorder ? 3 : 1); j++)
                        average += cell.elevation;


                    average /= neighborCount + j;
                    cell.elevation = average;
                }
            }

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Smoothing terrain", Util.secondsSince(d)));
        }

        private function stretchHeightMap():void
        {
            var d:Date = new Date();

            var tallest:Number = Number.NEGATIVE_INFINITY;
            for each (var cell:Cell in cells)
                if (cell.elevation > tallest)
                    tallest = cell.elevation;
            for each (cell in cells)
                if (cell.tectonicPlate.type != TectonicPlate.DEEP)
                    cell.elevation /= tallest;

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Stretch elevation", Util.secondsSince(d)));
        }

        public function setCornerHeights():void
        {
            var d:Date = new Date();

            for each (var corner:Corner in corners)
            {
                corner.elevation = 0;
                for each (var cell:Cell in corner.touches)
                    corner.elevation += cell.elevation;
                corner.elevation /= corner.touches.length;
            }

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Assign heights to vertices", Util.secondsSince(d)));
        }

        public function unuseCells():void
        {
            for each(var cell:Cell in cells)
            {
                cell.used = false;
            }
        }


        public function nextUnusedCell():Cell
        {
            var i:int = 0;
            for each(var cell:Cell in cells)
            {
                i++;
                if (!cell.used)
                {
                    return cell;
                }
            }

            return null;
        }


        public function getCellByPoint(p:Point):Cell
        {
            return cellsByPoints[JSON.stringify(p)];
        }

        public function getClosestCellToPoint(p:Point):Cell
        {
            var arr:Array = Util.toArray(quadTree.queryFromPoint(p, 100));
            var t:Point = Util.closestPoint(p, arr);
            return getCellByPoint(t);
        }


        private function makeModel():void
        {
            // Setup
            var d:Date;

            d = new Date();
            var voronoi:Voronoi = new Voronoi(points,
                    bounds);

            cells = new Vector.<Cell>();
            corners = new Vector.<Corner>();
            edges = new Vector.<Edge>();

            // Make cell dictionary
            var cellsDictionary:Dictionary = new Dictionary();
            for each (var point:Point in points)
            {
                var cell:Cell = new Cell();
                cell.index = cells.length;
                cell.point = point;
                cells.push(cell);
                cellsDictionary[point] = cell;
            }
            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Voronoi diagram", Util.secondsSince(d)));

            d = new Date();
            for each (cell in cells)
                voronoi.region(cell.point);
            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Voronoi regions", Util.secondsSince(d)));

            /**
             * Associative Mapping
             */

            d = new Date();
            cellsByPoints = {};
            for each (cell in cells)
            {
                cellsByPoints[JSON.stringify(cell.point)] = cell;
            }

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Cell dictionary", Util.secondsSince(d)));

            /**
             * Corners
             */

            var _cornerMap:Array = [];

            function makeCorner(point:Point):Corner
            {
                if (!point)
                {
                    return null;
                }
                for (var bucket:int = point.x - 1; bucket <= point.x + 1; bucket++)
                {
                    for each (var corner:Corner in _cornerMap[bucket])
                    {
                        var dx:Number = point.x - corner.point.x;
                        var dy:Number = point.y - corner.point.y;
                        if (dx * dx + dy * dy < 1e-6)
                        {
                            return corner;
                        }
                    }
                }

                bucket = int(point.x);

                if (!_cornerMap[bucket])
                {
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
            var libEdges:Vector.<com.nodename.delaunay.Edge> = voronoi.edges();
            for each (var libEdge:com.nodename.delaunay.Edge in libEdges)
            {
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

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Edges", Util.secondsSince(d)));

            /**
             * Cell Area
             */

            d = new Date();
            for each (cell in cells)
                cell.calculateArea();

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Cell areas", Util.secondsSince(d)));
        }


        private function setupEdge(edge:Edge):void
        {
            if (edge.d0 != null)
                edge.d0.edges.push(edge);

            if (edge.d1 != null)
                edge.d1.edges.push(edge);

            if (edge.v0 != null)
                edge.v0.protrudes.push(edge);

            if (edge.v1 != null)
                edge.v1.protrudes.push(edge);

            if (edge.d0 != null && edge.d1 != null)
            {
                addToCellList(edge.d0.neighbors,
                        edge.d1);
                addToCellList(edge.d1.neighbors,
                        edge.d0);
            }

            if (edge.v0 != null && edge.v1 != null)
            {
                addToCornerList(edge.v0.adjacent,
                        edge.v1);
                addToCornerList(edge.v1.adjacent,
                        edge.v0);
            }

            if (edge.d0 != null)
            {
                addToCornerList(edge.d0.corners,
                        edge.v0);
                addToCornerList(edge.d0.corners,
                        edge.v1);
            }

            if (edge.d1 != null)
            {
                addToCornerList(edge.d1.corners,
                        edge.v0);
                addToCornerList(edge.d1.corners,
                        edge.v1);
            }

            if (edge.v0 != null)
            {
                addToCellList(edge.v0.touches,
                        edge.d0);
                addToCellList(edge.v0.touches,
                        edge.d1);
            }

            if (edge.v1 != null)
            {
                addToCellList(edge.v1.touches,
                        edge.d0);
                addToCellList(edge.v1.touches,
                        edge.d1);
            }

            function addToCornerList(v:Vector.<Corner>,
                                     x:Corner):void
            {
                if (x != null && v.indexOf(x) < 0)
                {
                    v.push(x);
                }
            }

            function addToCellList(v:Vector.<Cell>,
                                   x:Cell):void
            {
                if (x != null && v.indexOf(x) < 0)
                {
                    v.push(x);
                }
            }
        }


        public function makePoints():void
        {
            var d:Date = new Date();

            points = new Vector.<Point>();
            quadTree = new QuadTree(bounds);

            // Make border points
            var gap:int = 5
            for (var i:int = gap; i < bounds.width; i += 2 * gap)
            {
                addPoint(new Point(i, gap));
                addPoint(new Point(i, bounds.height - gap));
            }

            for (i = 2 * gap; i < bounds.height - gap; i += 2 * gap)
            {
                addPoint(new Point(gap, i));
                addPoint(new Point(bounds.width - gap, i));
            }

            // Fill the rest of the area
            makePointsInArea(bounds);

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Make points", Util.secondsSince(d), points.length + " points\n" + (points.length / ((new Date().time - d.time) / 1000)).toFixed(2) + " points/second"));
        }


        private function makePointsInArea(area:Rectangle):void
        {
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

            while (queue.length > 0)
            {
                point = queue[0];

                for (var i:int = 0; i < precision; i++)
                {
                    angle = Rand.rand.next() * doublePI;
                    distance = Rand.rand.between(spacing, doubleSpacing);

                    candidate = new Point(point.x + distance * Math.cos(angle),
                            point.y + distance * Math.sin(angle));

                    // Check point distance to nearby points
                    box.x = candidate.x - spacing;
                    box.y = candidate.y - spacing;
                    if (quadTree.isRangePopulated(box))
                    {
                        candidate = null;
                    }
                    else
                    {
                        // Valid candidate
                        if (!area.contains(candidate.x, candidate.y))
                        {
                            // Candidate is outside the area, so don't include it
                            candidate = null;
                            continue;
                        }
                        break;
                    }
                }

                if (candidate)
                {
                    addPoint(candidate);
                    queue.push(candidate);
                }
                else
                {
                    // Remove the first point in queue
                    queue.shift();
                }
            }
        }


        private function addPoint(p:Point):void
        {
            points.push(p);
            quadTree.insert(p);
        }
    }
}
