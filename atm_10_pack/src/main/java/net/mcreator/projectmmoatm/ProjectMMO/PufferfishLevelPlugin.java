package net.mcreator.projectmmoatm.ProjectMMO;

import java.util.Optional;
import harmonised.pmmo.api.events.XpEvent;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.neoforge.common.NeoForge;
import net.puffish.skillsmod.SkillsMod;

@Mod("projectmmoatm")
public class PufferfishLevelPlugin {
	public PufferfishLevelPlugin(IEventBus modEventBus) {
        modEventBus.addListener(this::setup);
	}
    
    private void setup(final FMLCommonSetupEvent event) {
        // Register our event handler
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
                GainSkill(player, "pmmo_atm10:combat");
                break;
            case "archery":
                GainSkill(player, "pmmo_atm10:archery");
                break;
            case "magic":
                GainSkill(player, "pmmo_atm10:magic");
                break;
            case "agility":
                GainSkill(player, "pmmo_atm10:agility");
                break;
            case "endurance":
                GainSkill(player, "pmmo_atm10:endurance");
                break;
            case "mining":
            case "excavation":
            case "woodcutting":
                GainSkill(player, "pmmo_atm10:gathering");
                break;
        }
    }

    private static void GainSkill(ServerPlayer player, String skillName){
        ResourceLocation source = ResourceLocation.parse("pmmo_atm10:PufferfishLevelPlugin");
        ResourceLocation id = ResourceLocation.parse(skillName);

        SkillsMod skillsMod = SkillsMod.getInstance();
        Optional<Integer> totalPoints = skillsMod.getPointsTotal(player, id);

        if (!totalPoints.isPresent() || totalPoints.get() >= 50) {
            System.out.println("No points found... or more than 50.");

            return;
        }

        skillsMod.addPoints(player, id, source, 1, false);
    }
}