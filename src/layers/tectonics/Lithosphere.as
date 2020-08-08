package layers.tectonics
{
    import flash.geom.Point;
    import flash.utils.Dictionary;

    import global.Rand;
    import global.Util;
    import global.performance.PerformanceReport;
    import global.performance.PerformanceReportItem;

    import graph.*;

    import ui.AdvancedPropertiesUtil;

    public class Lithosphere
    {
        private var map:Map;

        public var tectonicPlates:Array = [];
        public var totalArea:Number;

        public function Lithosphere(map:Map)
        {
            this.map = map;

            pickStartingCells(AdvancedPropertiesUtil.currentValues.plateCount);
            expandPlates();
        }


        private function pickStartingCells(plateCount:int):void
        {
            // ~West/East Oceans
            var p:Point;

            for (var i:int = 0; i < 3; i++)
            {
                p = new Point(map.width * .05, map.height * (i + 1) / 4);
                addNewTectonicPlate(map.getClosestCellToPoint(p)).type = TectonicPlate.DEEP;
                p = new Point(map.width * .95, map.height * (i + 1) / 4);
                addNewTectonicPlate(map.getClosestCellToPoint(p)).type = TectonicPlate.DEEP;
            }

            // ~North/South Oceans
            p = new Point(map.width * (1 / 3), map.height * .95);
            addNewTectonicPlate(map.getClosestCellToPoint(p)).type = TectonicPlate.DEEP;
            p = new Point(map.width * (2 / 3), map.height * .95);
            addNewTectonicPlate(map.getClosestCellToPoint(p)).type = TectonicPlate.DEEP;
            p = new Point(map.width * (1 / 3), map.height * .05);
            addNewTectonicPlate(map.getClosestCellToPoint(p)).type = TectonicPlate.DEEP;
            p = new Point(map.width * (2 / 3), map.height * .05);
            addNewTectonicPlate(map.getClosestCellToPoint(p)).type = TectonicPlate.DEEP;

            for (i = 0; i < plateCount; i++)
            {
                var cell:Cell = null;
                while (!cell)
                {
                    p = new Point(Rand.rand.between(map.width * .1, map.width * .9),
                            Rand.rand.between(map.height * .3, map.height * .7));
                    cell = map.getClosestCellToPoint(p);
                }

                addNewTectonicPlate(cell, .8);
            }

            function addNewTectonicPlate(cell:Cell, power:Number = 1):TectonicPlate
            {
                var t:TectonicPlate = new TectonicPlate(tectonicPlates[tectonicPlates.length]);
                tectonicPlates.push(t);
                t.addCell(cell);
                cell.tectonicPlatePower = power;
                return t;
            }
        }


        private function expandPlates():void
        {
            var t:Date = new Date();

            for each (var tectonicPlate:TectonicPlate in tectonicPlates)
            {
                map.unuseCells();
                var queue:Vector.<Cell> = new Vector.<Cell>();
                // There's only one cell in here right now
                if (tectonicPlate.cells.length > 0)
                    queue.push(tectonicPlate.cells[0]);

                while (queue.length > 0)
                {
                    var cell:Cell = queue.shift();
                    for each (var neighbor:Cell in cell.neighbors)
                    {
                        if (!neighbor.used && neighbor.tectonicPlate != cell.tectonicPlate && neighbor.tectonicPlatePower < cell.tectonicPlatePower)
                        {
                            neighbor.tectonicPlatePower = cell.tectonicPlatePower - (Rand.rand.next() < AdvancedPropertiesUtil.currentValues.tectonicJitter ? Rand.rand.next() * .1 : .05);
                            //neighbor.tectonicPlatePower = cell.tectonicPlatePower - .05;
                            if (neighbor.tectonicPlate)
                                neighbor.tectonicPlate.removeCell(neighbor);

                            tectonicPlate.addCell(neighbor);
                            queue.push(neighbor);
                            neighbor.used = true;
                        }
                    }
                }
            }
            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Make tectonic plates", Util.secondsSince(t)));

            // Ensure there are no tectonic plate fragments
            var pass:int = 0;
            t = new Date();
            do
            {
                var fragments:Vector.<Cell> = getPlateFragments();
                for (var i:int = 0; i < fragments.length; i++)
                {
                    cell = fragments[i];
                    var neighbors:Vector.<Cell> = cell.neighbors.concat();
                    while (neighbors.length > 0)
                    {
                        neighbor = Cell(neighbors.removeAt(int(Rand.rand.next() * neighbors.length)));
                        if (cell.tectonicPlate != neighbor.tectonicPlate)
                        {
                            cell.tectonicPlate.removeCell(cell);
                            neighbor.tectonicPlate.addCell(cell);
                            fragments.removeAt(i--);
                            break;
                        }
                    }
                }
                pass++;
            } while (getPlateFragments().length > 0 && pass < 10);
            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Remove tectonic plate fragments", Util.secondsSince(t)));

            // Determine the tectonic plate borders
            t = new Date();
            var borderCells:Vector.<Cell> = new Vector.<Cell>();
            for each (cell in map.cells)
            {
                for each (neighbor in cell.neighbors)
                {
                    // Cell plate isn't the same as its neighbor,
                    // and the neighbor has a tectonic plate (collisions make no sense on map edges),
                    // and deep plates don't interact with each other (to keep the deep ocean floor even)
                    if (cell.tectonicPlate != neighbor.tectonicPlate && neighbor.tectonicPlate && (cell.tectonicPlate.type != TectonicPlate.DEEP && neighbor.tectonicPlate.type != TectonicPlate.DEEP))
                    {
                        cell.tectonicPlateBorder = true;
                        borderCells.push(cell);
                    }
                }
            }

            // Calculate the area for each tectonic plate
            totalArea = 0;
            for each (tectonicPlate in tectonicPlates)
            {
                if (tectonicPlate.type) continue;
                tectonicPlate.calculateArea();
                totalArea += tectonicPlate.area;
            }

            for each (tectonicPlate in tectonicPlates)
            {
                if (tectonicPlate.type) continue;
                tectonicPlate.areaPercent = Util.round(tectonicPlate.area / totalArea);
            }
            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Measure tectonic plates", Util.secondsSince(t)));

            // Set plates to either oceanic or continental
            t = new Date();
            var platesArray:Array = Util.toArray(tectonicPlates);
            platesArray.sortOn("area");
            var currentAreaPercent:Number = 0;
            for each (tectonicPlate in platesArray)
            {
                if (tectonicPlate.type)
                    continue;

                // Assign plate type
                tectonicPlate.type = currentAreaPercent < .3 ? TectonicPlate.CONTINENTAL : TectonicPlate.OCEANIC;
                currentAreaPercent += tectonicPlate.areaPercent;
            }

            for each (tectonicPlate in platesArray)
            {
                var height:Number = 0;
                switch (tectonicPlate.type)
                {
                    case TectonicPlate.CONTINENTAL:
                        height = Rand.rand.between(.3, .45);
                        break;
                    case TectonicPlate.OCEANIC:
                        height = Rand.rand.between(0, .25);
                        break;
                    case TectonicPlate.DEEP:
                        height = 0;
                        break;
                }

                for each(cell in tectonicPlate.cells)
                    cell.elevation = height;
            }
            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Tectonic plate types", Util.secondsSince(t)));

            // Set initial heights for borders
            // Cells pointing toward an edge will create a mountain
            // Cells pointing away from an edge will create a trench
            t = new Date();
            for each (cell in borderCells)
            {
                // Determine the cell's elevation based on its neighbors
                var margin:int = 45;
                for each (neighbor in cell.neighbors)
                {
                    if (cell.tectonicPlate != neighbor.tectonicPlate)
                    {
                        // 100% to form mountains on land, 20% chance to form mountains underwater
                        // This will cause mountain ranges on land and island chains in water
                        var chance:Number = cell.tectonicPlate.type == TectonicPlate.CONTINENTAL ? 1 : 0.2;
                        if (Rand.rand.next() > chance)
                            break;

                        var edge:Edge = cell.sharedEdge(neighbor);
                        if (edge)
                        {
                            var degreesToNeighbor:int = Util.angleBetweenTwoPoints(cell.point, neighbor.point);
                            var difference:int = Util.differenceBetweenTwoDegrees(cell.tectonicPlateDirection, degreesToNeighbor);
                            if (difference > 360 - margin || difference < 0 + margin)
                            {
                                cell.elevation = 1;
                                break;
                            }
                            if (difference > 180 - margin && difference < 180 + margin)
                            {
                                cell.elevation = 0;
                                break;
                            }
                        }
                    }
                }
            }

            // Remove empty plates
            for (i = 0; i < tectonicPlates.length; i++)
            {
                if (tectonicPlates[i].cells.length == 0)
                    tectonicPlates.splice(i--);
            }

            PerformanceReport.addPerformanceReportItem(new PerformanceReportItem("Apply tectonic plate collisions", Util.secondsSince(t)));
        }


        private function getPlateFragments():Vector.<Cell>
        {
            map.unuseCells();

            // Fragments are Cells that are not connected to the largest plate body with the same index
            // Determine plate bodies
            var bodies:Array = [];
            var queue:Vector.<Cell> = new Vector.<Cell>();
            var cell:Cell = map.cells[0];
            cell.used = true;
            queue.push(map.cells[0]);
            var currentTectonicPlate:TectonicPlate = cell.tectonicPlate;
            var currentBody:Vector.<Cell> = new Vector.<Cell>();

            while (queue.length > 0)
            {
                cell = queue.shift();
                currentBody.push(cell);

                for each (var neighbor:Cell in cell.neighbors)
                {
                    if (!neighbor.used && neighbor.tectonicPlate == cell.tectonicPlate)
                    {
                        neighbor.used = true;
                        queue.push(neighbor);
                    }
                }

                if (queue.length == 0)
                {
                    // Empty
                    bodies.push(currentBody);
                    currentBody = new Vector.<Cell>();
                    cell = map.nextUnusedCell();
                    if (cell)
                    {
                        currentTectonicPlate = cell.tectonicPlate;
                        queue.push(cell);
                        cell.used = true;
                    }
                }
            }

            // Determine the fragments by identifying the smallest bodies with a corresponding body belonging to the same tectonic plate
            var fragments:Vector.<Cell> = new Vector.<Cell>();
            var bodiesDictionary:Dictionary = new Dictionary();
            for each (var body:Vector.<Cell> in bodies)
            {
                var t:TectonicPlate = Cell(body[0]).tectonicPlate;
                // Largest body is the largest body of that tectonic plate
                if (!bodiesDictionary[t])
                {
                    bodiesDictionary[t] = body;
                } else
                {
                    var bodyInDictionary:Vector.<Cell> = bodiesDictionary[t];
                    if (body.length > bodyInDictionary.length)
                    {
                        fragments = fragments.concat(bodyInDictionary);
                        bodiesDictionary[t] = body;
                    } else
                    {
                        fragments = fragments.concat(body);
                    }
                }
            }

            return fragments;
        }
    }
}