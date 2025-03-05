package net.reign.atm10_pmmo.skills;

import java.util.Optional;

import harmonised.pmmo.api.events.XpEvent;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.neoforge.common.NeoForge;
import net.puffish.skillsmod.SkillsMod;

@Mod("atm10_pmmo")
public class PufferfishLevelPlugin {
    private static ResourceLocation _source;

	public PufferfishLevelPlugin(IEventBus modEventBus) {
        modEventBus.addListener(this::setup);
	}
    
    private void setup(final FMLCommonSetupEvent event) {
        // Register our event handler
        _source = ResourceLocation.parse("atm10_pmmo:pufferfishlevelplugin");
        Register();
    }
    
    public static void Register() {
        NeoForge.EVENT_BUS.addListener(PufferfishLevelPlugin::XpGainedEvent);
    }

    private static void XpGainedEvent(XpEvent event) {
        if (!(event.getEntity() instanceof ServerPlayer player) || !event.isLevelUp())
            return;

        boolean earnSkillPoint = (event.endLevel() % 10) == 0;
        
        if (!earnSkillPoint)
            return;

        switch (event.skill)
        {
            case "combat":
                GainSkill(player, "atm10_pmmo:combat");
                break;
            case "archery":
                GainSkill(player, "atm10_pmmo:archery");
                break;
            case "magic":
                GainSkill(player, "atm10_pmmo:magic");
                break;
            case "agility":
                GainSkill(player, "atm10_pmmo:agility");
                break;
            case "endurance":
                GainSkill(player, "atm10_pmmo:endurance");
                break;
            case "mining":
            case "excavation":
            case "woodcutting":
                GainSkill(player, "atm10_pmmo:gathering");
                break;
        }
    }

    private static void GainSkill(ServerPlayer player, String skillName){
        ResourceLocation id = ResourceLocation.parse(skillName);

        SkillsMod skillsMod = SkillsMod.getInstance();
        Optional<Integer> totalPoints = skillsMod.getPointsTotal(player, id);

        if (!totalPoints.isPresent() || totalPoints.get() >= 50)
            return;

        skillsMod.addPoints(player, id, _source, 1, false);
    }
}