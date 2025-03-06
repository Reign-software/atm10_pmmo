package net.reign.atm10_pmmo.jade;

import harmonised.pmmo.api.APIUtils;
import harmonised.pmmo.api.enums.EventType;
import harmonised.pmmo.api.enums.ReqType;
import harmonised.pmmo.config.Config;
import net.reign.atm10_pmmo.RPGMod;
import net.minecraft.ChatFormatting;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.level.block.Block;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.Level;
import snownee.jade.api.BlockAccessor;
import snownee.jade.api.IBlockComponentProvider;
import snownee.jade.api.ITooltip;
import snownee.jade.api.IWailaClientRegistration;
import snownee.jade.api.IWailaPlugin;
import snownee.jade.api.WailaPlugin;
import snownee.jade.api.config.IPluginConfig;

import java.text.DecimalFormat;
import java.util.Map;

/**
 * Simple Plugin for Jade to display PMMO requirements in tooltips
 * using the official PMMO API utilities
 */
@WailaPlugin
public class PMmoJadePlugin implements IWailaPlugin {
    // Simple unique identifier for our component
    public static final ResourceLocation PMMO_ID = ResourceLocation.bySeparator(RPGMod.MODID,':');
    private static final DecimalFormat XP_FORMAT = new DecimalFormat("#,##0.0");

    @Override
    public void registerClient(IWailaClientRegistration registration) {
        // Register our component provider for all blocks
        registration.registerBlockComponent(BlockRequirementsProvider.INSTANCE, Block.class);
		harmonised.pmmo.config.Config.SKILLUP_UNLOCKS.set(false);
    }

    public static class BlockRequirementsProvider implements IBlockComponentProvider {
        public static final BlockRequirementsProvider INSTANCE = new BlockRequirementsProvider();

        @Override
        public ResourceLocation getUid() {
            return PMMO_ID;
        }

        @Override
        public void appendTooltip(ITooltip tooltip, BlockAccessor accessor, IPluginConfig config) {
            Player player = accessor.getPlayer();
            Level level = accessor.getLevel();
            BlockPos pos = accessor.getPosition();
            BlockState state = accessor.getBlockState();
            
            // Skip if we can't get proper data
            if (player == null || level == null || pos == null || state == null) {
                return;
            }
            
            try {
                // Get requirements and XP data
                Map<String, Long> breakReqs = APIUtils.getRequirementMap(pos, level, ReqType.BREAK);
                Map<String, Long> interactReqs = APIUtils.getRequirementMap(pos, level, ReqType.INTERACT);
                Map<String, Long> breakXp = APIUtils.getXpAwardMap(level, pos, EventType.BLOCK_BREAK, player);
                boolean breakhasNonZeroRequirements = breakReqs.values().stream().anyMatch(l -> l > 0);
                boolean interacthasNonZeroRequirements = interactReqs.values().stream().anyMatch(l -> l > 0);
                
                // Only show tooltip if we have data to display
                if ((!breakReqs.isEmpty() && breakhasNonZeroRequirements) || (!interactReqs.isEmpty() && interacthasNonZeroRequirements)) {
                    tooltip.add(Component.empty());
                    tooltip.add(Component.translatable("pmmo.jade.requirements").withStyle(ChatFormatting.GOLD, ChatFormatting.BOLD));
                }

                // Display break requirements with player's current levels
                if (!breakReqs.isEmpty() && breakhasNonZeroRequirements) {

                    tooltip.add(Component.translatable("pmmo.jade.break_requirements").withStyle(ChatFormatting.YELLOW));
                    
                    for (Map.Entry<String, Long> entry : breakReqs.entrySet()) {
                        String skillName = entry.getKey();
                        long reqLevel = entry.getValue();
                        
                        // Skip skills with 0 requirements
                        if (reqLevel <= 0) continue;
                        
                        long playerLevel = APIUtils.getLevel(skillName, player);
                        var skillConfig = Config.skills().get(skillName);
                        ChatFormatting color = playerLevel >= reqLevel ? ChatFormatting.GREEN : ChatFormatting.RED;

                        if (skillConfig != null && skillConfig.getIcon() != null) {
                            Component skillComponent = Component.translatable("pmmo." + skillName).withColor(skillConfig.getColor());
                            tooltip.add(Component.literal("  ")
                                            .append(skillComponent).withStyle(color)
                                            .append(Component.literal(": " + playerLevel + "/" + reqLevel).withStyle(color)));
                        }
                        else {
                            Component skillComponent = Component.translatable("pmmo." + skillName);
                            tooltip.add(Component.literal("  ")
                                            .append(skillComponent).withStyle(color)
                                            .append(Component.literal(": " + playerLevel + "/" + reqLevel).withStyle(color)));
                        }
                    }
                }
                
                // Display interact requirements with player's current levels
                if (!interactReqs.isEmpty() && interacthasNonZeroRequirements) {
                    tooltip.add(Component.translatable("pmmo.jade.interact_requirements").withStyle(ChatFormatting.YELLOW));
                    
                    for (Map.Entry<String, Long> entry : interactReqs.entrySet()) {
                        String skillName = entry.getKey();
                        long reqLevel = entry.getValue();
                        long playerLevel = APIUtils.getLevel(skillName, player);
                        
                        var skillConfig = Config.skills().get(skillName);
                        ChatFormatting color = playerLevel >= reqLevel ? ChatFormatting.GREEN : ChatFormatting.RED;
                        
                        
                        if (skillConfig != null && skillConfig.getIcon() != null) {
                            Component skillComponent = Component.translatable("pmmo." + skillName).withColor(skillConfig.getColor());
                            tooltip.add(Component.literal("  ")
                                                    .append(skillComponent).withStyle(color)
                                                    .append(Component.literal(": " + playerLevel + "/" + reqLevel).withStyle(color)));
                        }
                        else
                        {
                            Component skillComponent = Component.translatable("pmmo."+skillName);
                            tooltip.add(Component.literal("  ")
                                                    .append(skillComponent).withStyle(color)
                                                    .append(Component.literal(": " + playerLevel + "/" + reqLevel).withStyle(color)));
                        }
                    }
                }
                
                // Display XP rewards
                if (!breakXp.isEmpty()) {

                    boolean hasNonZeroRequirements = breakXp.values().stream().anyMatch(l -> l > 0);

                    if (hasNonZeroRequirements) {
                        tooltip.add(Component.translatable("pmmo.jade.break_xp").withStyle(ChatFormatting.AQUA));
                        
                        breakXp.entrySet().stream()
                            .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                            .forEach(entry -> {
                                String skillName = entry.getKey();
                                long xpValue = entry.getValue();
                                var skillConfig = Config.skills().get(skillName);
                                
                                if (xpValue > 0) {
                                    
                                    if (skillConfig != null && skillConfig.getIcon() != null) {
                                        Component skillComponent = Component.translatable("pmmo." + skillName).withColor(skillConfig.getColor());
                                        tooltip.add(Component.literal("  ")
                                                                .append(skillComponent)
                                                                .append(Component.literal(": " + formatXp(xpValue)).withStyle(ChatFormatting.GREEN)));
                                    }
                                    else
                                    {
                                        Component skillComponent = Component.translatable("pmmo."+skillName).withStyle(ChatFormatting.WHITE);
                                        tooltip.add(Component.literal("  ")
                                                                .append(skillComponent)
                                                                .append(Component.literal(": " + formatXp(xpValue)).withStyle(ChatFormatting.GREEN)));
                                    }
                                }
                            });
                    }
                }
            }
            catch (Exception e) {
                tooltip.add(Component.literal("Error loading PMMO data").withStyle(ChatFormatting.RED));
                RPGMod.LOGGER.error("Error in PMMO Jade integration: " + e.getMessage(), e);
            }
        }
        
        /**
         * Formats an XP value for display in the tooltip
         */
        private String formatXp(long xp) {
            if (xp >= 1000) {
                return XP_FORMAT.format(xp);
            }
            return String.valueOf(xp);
        }
    }
}
