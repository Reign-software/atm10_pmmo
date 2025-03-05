package net.reign.atm10_pmmo.client;

import dev.ftb.mods.ftbultimine.integration.FTBUltiminePlugin;
import net.minecraft.world.entity.player.Player;

public class FTBUltimine implements FTBUltiminePlugin {
    @Override
    public boolean canUltimine(Player player) {
        return false;
    }
}
