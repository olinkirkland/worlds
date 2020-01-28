package layers.geography {
    import global.Util;

    import graph.Cell;

    public class Hydrology {
        private var map:Map;

        public function Hydrology(map:Map) {
            this.map = map;

            precipitate();

            //distributeWater();
        }

        public function precipitate():void {
            for each (var cell:Cell in map.cells)
                cell.water += cell.precipitation;
        }

        public function distributeWater():void {
            var d:Date = new Date();
            Util.log("> Distributing water...");
            for each (var cell:Cell in map.cells)
                cell.calculateOutflows();

            for each (cell in map.cells)
                cell.calculateInflows();

            map.setCornerHeights();

            Util.log("  " + Util.secondsSince(d));
        }
    }
}