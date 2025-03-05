package net.reign.atm10_pmmo.skills;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.logging.Logger;

import harmonised.pmmo.api.events.XpEvent;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.event.lifecycle.FMLCommonSetupEvent;
import net.neoforged.neoforge.common.NeoForge;
import net.puffish.skillsmod.SkillsMod;
import net.reign.atm10_pmmo.RPGMod;

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
        
        // Calculate how many skill point thresholds were crossed
        int startThreshold = (int)(event.startLevel() / 10);
        int endThreshold = (int)(event.endLevel() / 10);
        int pointsToAward = endThreshold - startThreshold;
        RPGMod.LOGGER.info("Player " + player.getName() + " gained " + pointsToAward + " skill points from " + event.skill + " level up (from " + event.startLevel() + " to " + event.endLevel() + ")");
        // If no thresholds crossed, exit
        if (pointsToAward <= 0)
            return;

        switch (event.skill)
        {
            case "combat":
                GainSkill(player, "atm10_pmmo:combat", pointsToAward);
                break;
            case "archery":
                GainSkill(player, "atm10_pmmo:archery", pointsToAward);
                break;
            case "magic":
                GainSkill(player, "atm10_pmmo:magic", pointsToAward);
                break;
            case "agility":
                GainSkill(player, "atm10_pmmo:agility", pointsToAward);
                break;
            case "endurance":
                GainSkill(player, "atm10_pmmo:endurance", pointsToAward);
                break;
            case "mining":
            case "excavation":
            case "woodcutting":
                GainSkill(player, "atm10_pmmo:gathering", pointsToAward);
                break;
        }
    }

    private static void GainSkill(ServerPlayer player, String skillName, int pointsToAward) {
        ResourceLocation id = ResourceLocation.parse(skillName);

        SkillsMod skillsMod = SkillsMod.getInstance();
        Optional<Integer> totalPoints = skillsMod.getPointsTotal(player, id);
        
        RPGMod.LOGGER.info("Player " + player.getName() + " has " + totalPoints.orElse(0) + " points in " + id);
        
        // Get max points from cache or compute if not present
        int maxPoints = getMaxSkillPoints(id, skillsMod);
        
        if (!totalPoints.isPresent())
            return;
            
        int currentPoints = totalPoints.get();
        int pointsAwarded = 0;
        
        // Calculate how many points we can actually award without exceeding the maximum
        pointsAwarded = Math.min(pointsToAward, maxPoints - currentPoints);
        
        // Add all points at once if there are any to add
        if (pointsAwarded > 0) {
            skillsMod.addPoints(player, id, _source, pointsAwarded, false);
            sendSkillPointNotification(player, id, pointsAwarded);
        }
    }
    
    /**
     * Sends a notification to the player that they've gained skill points
     * 
     * @param player The player who gained the skill points
     * @param skillId The skill tree ID
     * @param pointsAwarded The number of points awarded
     */
    private static void sendSkillPointNotification(ServerPlayer player, ResourceLocation skillId, int pointsAwarded) {
        // Format the skill name for display (convert 'atm10_pmmo:combat' to 'Combat')
        String skillName = capitalizeSkillName(skillId.getPath());
        
        // Get current available points after the addition
        Optional<Integer> availablePoints = SkillsMod.getInstance().getPointsLeft(player, skillId);
        String pointsText = availablePoints.isPresent() ? availablePoints.get().toString() : String.valueOf(pointsAwarded);
        
        // Create pluralized text for the notification
        String notification = pointsAwarded == 1 
            ? "atm10_pmmo.skill_point_gained" 
            : "atm10_pmmo.skill_points_gained";
        
        // Create and send the notification message
        Component message = Component.translatable(notification, 
                Component.literal(skillName), 
                Component.literal(String.valueOf(pointsAwarded)),
                Component.literal(pointsText));
        
        player.sendSystemMessage(Component.literal("§a✦ ").append(message));
        
        // Play a pleasant sound effect - slightly louder for multiple points
        float volume = Math.min(0.75f + (pointsAwarded * 0.05f), 1.0f);
        player.level().playSound(null, player.getX(), player.getY(), player.getZ(), 
                SoundEvents.PLAYER_LEVELUP, SoundSource.PLAYERS, volume, 1.5f);
    }
    
    /**
     * Helper method to capitalize and format skill names
     */
    private static String capitalizeSkillName(String path) {
        // Convert skill path like "combat" to "Combat"
        if (path == null || path.isEmpty()) {
            return "";
        }
        return path.substring(0, 1).toUpperCase() + path.substring(1);
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
        RPGMod.LOGGER.info("Getting max points for " + treeId);
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