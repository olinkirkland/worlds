package layers.geography {
    import global.Util;

    import graph.Cell;

    public class Hydrology {
        private var map:Map;

        public function Hydrology(map:Map) {
            this.map = map;

            /**
             * Precipitation
             */

            for each (var cell:Cell in map.cells)
                cell.water += cell.precipitation;

            calculateFlows();
        }

        private function calculateFlows():void {
            /**
             * Runoff
             */

            for each (var cell:Cell in map.cells)
                cell.calculateOutflows();

            for each (cell in map.cells)
                cell.calculateInflows();
        }
    }
}