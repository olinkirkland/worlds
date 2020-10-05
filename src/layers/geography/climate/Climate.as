package layers.geography.climate
{
    import global.Util;

    import graph.Cell;

    import ui.Settings;

    public class Climate
    {
        private var map:Map;

        private var temperatureLevelsDefinitions:Array;
        private var moistureLevelDefinitions:Array;

        private static const frosty:String = "frosty";
        private static const cold:String = "cold";
        private static const temperate:String = "temperate";
        private static const hot:String = "hot";

        private static const arid:String = "arid";
        private static const dry:String = "dry";
        private static const humid:String = "humid";
        private static const wet:String = "wet";

        public function Climate(map:Map)
        {
            this.map = map;

            // Determine temperature
            for each (var cell:Cell in map.cells)
            {
                cell.temperature = 1 - (Math.abs(2 * (cell.point.y / map.height) - (1 + Settings.properties.equatorOffset)) * Settings.properties.poleTemperatureModifier);
                if (!cell.ocean)
                    cell.temperature -= (cell.elevationAboveSeaLevel) * Settings.properties.elevationTemperatureModifier;
                cell.temperature = Util.fixed(cell.temperature, 2);
                cell.temperature = Math.min(Math.max(0, cell.temperature), 1);
            }

            // Determine biomes
            temperatureLevelsDefinitions = [
                {name: frosty, minimum: 0, maximum: .1},
                {name: cold, minimum: .1, maximum: .3},
                {name: temperate, minimum: .3, maximum: .8},
                {name: hot, minimum: .8, maximum: 1}
            ];

            moistureLevelDefinitions = [
                {name: arid, minimum: 0, maximum: .05},
                {name: dry, minimum: .05, maximum: .3},
                {name: humid, minimum: .3, maximum: .6},
                {name: wet, minimum: .6, maximum: 1}
            ];

            for each (cell in map.cells)
                assignBiomeTypeToCell(cell);
        }

        private function assignBiomeTypeToCell(cell:Cell):void
        {
            /**
             * Determines a biome from a cell's defaultProperties
             */

            if (cell.ocean)
                cell.biomeType = Biome.OCEAN;

            var t:String = null;
            for each (var temperatureLevel:Object in temperatureLevelsDefinitions)
                if (cell.temperature >= temperatureLevel.minimum && cell.temperature <= temperatureLevel.maximum)
                    t = temperatureLevel.name;
            cell.temperatureClimateDescriptor = t;

            var m:String = null;
            for each (var moistureLevel:Object in moistureLevelDefinitions)
                if (cell.moisture >= moistureLevel.minimum && cell.moisture <= moistureLevel.maximum)
                    m = moistureLevel.name;
            cell.moistureClimateDescriptor = m;

            var type:String = null;

            switch (t)
            {
                case frosty:
                    type = Biome.TUNDRA;
                    break;

                case cold:
                    if (m == arid) type = Biome.TUNDRA;
                    else if (m == dry || m == humid || m == wet) type = Biome.TAIGA;
                    break;

                case temperate:
                    if (m == arid) type = Biome.DESERT;
                    else if (m == dry) type = Biome.GRASSLAND;
                    else if (m == humid || m == wet) type = Biome.SEASONAL_FOREST;
                    break;

                case hot:
                    if (m == arid) type = Biome.DESERT;
                    else if (m == dry) type = Biome.SHRUBLAND;
                    else if (m == humid || m == wet) type = Biome.TROPICAL_RAINFOREST;
                    break;
            }

            cell.biomeType = type;
        }
    }
}