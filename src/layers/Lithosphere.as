package layers {
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
            Util.log("Time taken: " + Util.secondsSince(t));
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

            // Ensure there are no tectonic plate pieces floating
//            do {
//                var fragments:Vector.<Cell> = getPlateFragments();
//            } while (fragments.length > 0)
            getPlateFragments();
        }

        private function getPlateFragments():Vector.<Cell> {
            map.unuseCells();

            // Fragments are Cells that are not connected to the largest plate body with the same index
            // Determine Plate bodies
            var bodies:Array = [];
            var queue:Vector.<Cell> = new Vector.<Cell>();
            queue.push(map.cells[0]);
            var currentIndex:int;
            while (queue.length > 0) {
                var cell:Cell = queue.shift();
                cell.used = true;

                for each (var neighbor:Cell in cell.neighbors) {
                    if (neighbor.tectonicPlate == cell.tectonicPlate) {

                        queue.push(neighbor);
                    }
                }

                if (queue.length == 0 && map.nextUnusedCell())
                    queue.push(map.nextUnusedCell());
            }


            var fragments:Vector.<Cell> = new Vector.<Cell>();
            return fragments;
        }
    }
}
