package layers {
    import flash.utils.Dictionary;

    import graph.Cell;

    import util.Rand;
    import util.Util;

    public class Lithosphere {
        private var rand:Rand;
        private var map:Map;

        public var tectonicPlates:Object = {};

        public function Lithosphere(map:Map) {
            this.map = map;
            rand = new Rand(map.rand.seed);

            var t:Date = new Date();
            Util.log("Making lithosphere...");
            pickStartingCells(rand.between(15, 20));
            expandPlates();
            Util.log(Util.secondsSince(t));
        }

        private function pickStartingCells(plateCount:int):void {
            for (var i:int = 0; i < plateCount; i++) {
                var cell:Cell = map.cells[int(rand.next() * map.cells.length)];

                if (!cell.tectonicPlate) {
                    var t:TectonicPlate = new TectonicPlate(i);
                    tectonicPlates[t.index] = t;
                    t.addCell(cell);
                    cell.tectonicPlatePower = 100;
                }
            }
        }

        private function expandPlates():void {
            for each (var tectonicPlate:TectonicPlate in tectonicPlates) {
                map.unuseCells();
                var queue:Vector.<Cell> = new Vector.<Cell>();
                // There's only one cell in here right now
                if (tectonicPlate.cells.length > 0)
                    queue.push(tectonicPlate.cells[0]);

                while (queue.length > 0) {
                    var cell:Cell = queue.shift();
                    for each (var neighbor:Cell in cell.neighbors) {
                        if (!neighbor.used && neighbor.tectonicPlate != cell.tectonicPlate && neighbor.tectonicPlatePower < cell.tectonicPlatePower) {
                            neighbor.tectonicPlatePower = cell.tectonicPlatePower - (rand.next() * 2);
                            if (neighbor.tectonicPlate)
                                neighbor.tectonicPlate.removeCell(neighbor);

                            tectonicPlate.addCell(neighbor);
                            queue.push(neighbor);
                            neighbor.used = true;
                        }
                    }
                }
            }

            // Ensure there are no tectonic plate fragments
            while (getPlateFragments().length > 0) {
                var fragments:Vector.<Cell> = getPlateFragments();
                for each (cell in fragments)
                    cell.fragment = true;
                do {
                    for (var i:int = 0; i < fragments.length; i++) {
                        cell = fragments[i];
                        for each (neighbor in cell.neighbors) {
                            if (cell.tectonicPlate != neighbor.tectonicPlate) {
                                cell.tectonicPlate.removeCell(cell);
                                neighbor.tectonicPlate.addCell(cell);
                                fragments.removeAt(i--);
                                break;
                            }
                        }
                    }
                } while (fragments.length > 0)
            }
        }

        private function getPlateFragments():Vector.<Cell> {
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

            while (queue.length > 0) {
                cell = queue.shift();
                currentBody.push(cell);

                for each (var neighbor:Cell in cell.neighbors) {
                    if (!neighbor.used && neighbor.tectonicPlate == cell.tectonicPlate) {
                        neighbor.used = true;
                        queue.push(neighbor);
                    }
                }

                if (queue.length == 0) {
                    // Empty
                    bodies.push(currentBody);
                    currentBody = new Vector.<Cell>();
                    cell = map.nextUnusedCell();
                    if (cell) {
                        currentTectonicPlate = cell.tectonicPlate;
                        queue.push(cell);
                        cell.used = true;
                    }
                }
            }

            // Determine the fragments by identifying the smallest bodies with a corresponding body belonging to the same tectonic plate
            var fragments:Vector.<Cell> = new Vector.<Cell>();
            var bodiesDictionary:Dictionary = new Dictionary();
            for each (var body:Vector.<Cell> in bodies) {
                var t:TectonicPlate = Cell(body[0]).tectonicPlate;
                // Largest body is the largest body of that tectonic plate
                if (!bodiesDictionary[t]) {
                    bodiesDictionary[t] = body;
                } else {
                    var bodyInDictionary:Vector.<Cell> = bodiesDictionary[t];
                    if (body.length > bodyInDictionary.length) {
                        fragments = fragments.concat(bodyInDictionary);
                        bodiesDictionary[t] = body;
                    } else {
                        fragments = fragments.concat(body);
                    }
                }
            }

            return fragments;
        }
    }
}