package net.reign.atm10_pmmo.skills;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.logging.Logger;

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
    // Cache for storing the max skill points for each tree
    private static final Map<ResourceLocation, Integer> MAX_POINTS_CACHE = new HashMap<>();
    private static final Logger LOGGER = Logger.getLogger("atm10_pmmo");
    
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

    private static void GainSkill(ServerPlayer player, String skillName) {
        ResourceLocation id = ResourceLocation.parse(skillName);

        SkillsMod skillsMod = SkillsMod.getInstance();
        Optional<Integer> totalPoints = skillsMod.getPointsTotal(player, id);
        
        // Get max points from cache or compute if not present
        int maxPoints = getMaxSkillPoints(id, skillsMod);
        
        if (!totalPoints.isPresent() || totalPoints.get() >= maxPoints)
            return;

        skillsMod.addPoints(player, id, _source, 1, false);
    }
    
    /**
     * Gets the maximum skill points for a given tree ID, using a cache to avoid repeated lookups
     * 
     * @param treeId The ResourceLocation ID of the skill tree
     * @param skillsMod The SkillsMod instance
     * @return The maximum number of skill points for the tree
     */
    private static int getMaxSkillPoints(ResourceLocation treeId, SkillsMod skillsMod) {
        // Check if we already have this value cached
        if (MAX_POINTS_CACHE.containsKey(treeId)) {
            return MAX_POINTS_CACHE.get(treeId);
        }
        
        // If not in cache, compute and store it
        var skills = skillsMod.getSkills(treeId);
        
        int maxPoints = 0;
        if (skills.isPresent()) {
            maxPoints = skills.get().size();
            // Cache the result
            MAX_POINTS_CACHE.put(treeId, maxPoints);
            LOGGER.info("Cached max points for " + treeId + ": " + maxPoints);
        } else {
            LOGGER.warning("Could not find skills for tree: " + treeId);
        }
        
        return maxPoints;
    }
}