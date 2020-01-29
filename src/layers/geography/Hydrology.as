package layers.geography {
    import global.Util;

    import graph.Cell;

    public class Hydrology {
        private var map:Map;
        public var rivers:Vector.<River>;

        public function Hydrology(map:Map) {
            this.map = map;
            rivers = new Vector.<River>();
        }

        public function addRiver():River {
            var river:River = new River();
            river.index = rivers.length;
            rivers.push(river);
            return river;
        }

        public function sequence():void {
            precipitate();
            for (var i:int = 0; i < 30; i++)
                distributeWater();

            map.update();
        }

        public function precipitate():void {
            for each (var cell:Cell in map.cells)
                cell.water += cell.precipitation;
        }

        public function distributeWater():void {
            var d:Date = new Date();
            //Util.log("> Distributing water...");
            for each (var cell:Cell in map.cells)
                cell.calculateOutflows();

            for each (cell in map.cells)
                cell.calculateInflows();

            //Util.log("  " + Util.secondsSince(d));
        }
    }
}