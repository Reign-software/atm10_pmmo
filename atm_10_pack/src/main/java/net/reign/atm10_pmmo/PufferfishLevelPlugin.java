package net.reign.atm10_pmmo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.logging.Logger;

import com.hollingsworth.arsnouveau.api.event.SpellCastEvent;
import harmonised.pmmo.api.enums.EventType;
import harmonised.pmmo.api.APIUtils;
import harmonised.pmmo.api.events.XpEvent;
import harmonised.pmmo.core.Core;
import harmonised.pmmo.util.TagUtils;
import net.minecraft.nbt.CompoundTag;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.neoforged.neoforge.event.entity.player.PlayerEvent;
import net.puffish.skillsmod.SkillsMod;

import java.util.List;

public class PufferfishLevelPlugin {
    private static ResourceLocation _source = ResourceLocation.parse("atm10_pmmo:pufferfishlevelplugin");
    // Cache for storing the max skill points for each tree
    private static final Map<ResourceLocation, Integer> MAX_POINTS_CACHE = new HashMap<>();
    private static final Logger LOGGER = Logger.getLogger("atm10_pmmo");

    public static void CraftEventHandler(PlayerEvent.ItemCraftedEvent event) {
        if (!event.getEntity().isFakePlayer())
            return;
    
        Core core = Core.get(event.getEntity().level());
        CompoundTag eventHookOutput = new CompoundTag();
        boolean serverSide = !event.getEntity().level().isClientSide; 
        
        if (serverSide) {
            eventHookOutput = core.getEventTriggerRegistry().executeEventListeners(EventType.CRAFT, event, new CompoundTag());
            
            // Try to get more accurate position from container if possible
            ServerPlayer fakePlayer = (ServerPlayer) event.getEntity();

            // Process perks
            CompoundTag perkOutput = TagUtils.mergeTags(eventHookOutput, core.getPerkRegistry().executePerk(EventType.CRAFT, event.getEntity(), eventHookOutput));
            Map<String, Long> xpAward = core.getExperienceAwards(EventType.CRAFT, event.getCrafting(), event.getEntity(), perkOutput);
            
            // Get all players on the server
            List<ServerPlayer> allPlayers = getAllServerPlayers(fakePlayer);
            
            core.awardXP(allPlayers, xpAward);
        }
    }

    public static void ArsSpellCastExp(SpellCastEvent event)
    {
        if (!(event.getEntity() instanceof ServerPlayer player))
            return;
        
        APIUtils.addXp("magic", player, 20);
    }

    /**
     * Get all players currently on the server
     * 
     * @param player Reference player (needed for server access)
     * @return List of all ServerPlayer objects currently online
     */
    public static List<ServerPlayer> getAllServerPlayers(ServerPlayer player) {
        List<ServerPlayer> allPlayers = new ArrayList<>();
        
        if (player != null) {
            
            var server = player.getServer();

            if (server != null) {
                allPlayers.addAll(server.getPlayerList().getPlayers());
            }
        }
        
        return allPlayers;
    }
    
    public static void XpGainedEvent(XpEvent event) {
        if (!(event.getEntity() instanceof ServerPlayer player) || !event.isLevelUp())
            return;

        SkillsMod skillsMod = SkillsMod.getInstance();

        switch (event.skill)
        {
            case "combat" -> GainSkill(player, "atm10_pmmo:combat", event.endLevel(), skillsMod);
            case "archery" -> GainSkill(player, "atm10_pmmo:archery", event.endLevel(), skillsMod);
            case "magic" -> GainSkill(player, "atm10_pmmo:magic", event.endLevel(), skillsMod);
            case "agility" -> GainSkill(player, "atm10_pmmo:agility", event.endLevel(), skillsMod);
            case "endurance" -> GainSkill(player, "atm10_pmmo:endurance", event.endLevel(), skillsMod);
            case "mining", "farming", "woodcutting" -> {
                long totalLevel = APIUtils.getLevel("mining", player);
                totalLevel += APIUtils.getLevel("woodcutting", player);
                
                GainSkill(player, "atm10_pmmo:gathering", totalLevel, skillsMod);
            }
        }
    }

    private static void GainSkill(ServerPlayer player, String skillTree, long endLevel, SkillsMod skillsMod) {
        ResourceLocation id = ResourceLocation.parse(skillTree);
        
        int levelDiv = 10;

        // We treat these as the same skill.
        if (skillTree == "atm10_pmmo:gathering")
            levelDiv = 20;

        Optional<Integer> totalPoints = skillsMod.getPointsTotal(player, id);
        int pointsToAward = (int)(endLevel / levelDiv) - totalPoints.orElse(0);
        
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
            sendSkillPointNotification(player, id, pointsAwarded, skillsMod);
        }
    }
    
    /**
     * Sends a notification to the player that they've gained skill points
     * 
     * @param player The player who gained the skill points
     * @param skillId The skill tree ID
     * @param pointsAwarded The number of points awarded
     */
    private static void sendSkillPointNotification(ServerPlayer player, ResourceLocation skillId, int pointsAwarded, SkillsMod skillsMod) {
        // Format the skill name for display (convert 'atm10_pmmo:combat' to 'Combat')
        String skillName = capitalizeSkillName(skillId.getPath());
        
        // Get current available points after the addition
        Optional<Integer> availablePoints = skillsMod.getPointsLeft(player, skillId);
        int pointsAvailable = availablePoints.orElse(pointsAwarded);
        String pointsText = String.valueOf(pointsAvailable);
        
        // Create pluralized text for the notification
        String notification = pointsAwarded == 1 
            ? "atm10_pmmo.skill_point_gained" 
            : "atm10_pmmo.skill_points_gained";
        
        // Create and send the notification message
        Component message = Component.translatable(notification, 
                Component.literal(String.valueOf(pointsAwarded)),
                Component.literal(skillName), 
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