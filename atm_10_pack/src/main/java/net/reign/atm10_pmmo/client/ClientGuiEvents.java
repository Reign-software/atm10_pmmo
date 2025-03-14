package net.reign.atm10_pmmo.client;

import java.util.Optional;

import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.inventory.InventoryScreen;
import net.minecraft.network.chat.Component;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.api.distmarker.OnlyIn;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.neoforge.client.event.ScreenEvent;
import net.puffish.skillsmod.client.SkillsClientMod;

import net.reign.atm10_pmmo.RPGMod;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.client.gui.components.ImageButton;
import net.minecraft.client.gui.components.Tooltip;
import net.minecraft.client.gui.components.WidgetSprites;


public class ClientGuiEvents {

    private static final int BUTTON_WIDTH = 20;
    private static final int BUTTON_HEIGHT = 18;
    
  

    @OnlyIn(Dist.CLIENT)
    @SubscribeEvent
    public void onGuiInit(ScreenEvent.Init.Post event) {
        if (event.getScreen() instanceof InventoryScreen inv) {
       /*   
            // enabled, disabled, enabled focused, disabled focused
            var button = new WidgetSprites(SKILLS_BUTTON_TEXTURE, SKILLS_BUTTON_TEXTURE_PRESSED);

            // Add a button with a skills icon
            event.addListener(new ImageButton(
                inv.getGuiLeft() + 150, inv.height / 2 - 22, BUTTON_WIDTH, BUTTON_HEIGHT,  // x, y, width, height
                button,
                (b) -> {
                    openPufferfishSkillsScreen();
                },
                Component.translatable("atm10_pmmo.skills_button.tooltip")
            ));
        
            */
  
             var button = Button.builder(Component.literal("S"), (b) -> {
                openPufferfishSkillsScreen();
             })
             .pos(inv.getGuiLeft() + 150, inv.height / 2 - 22)
             .size(BUTTON_WIDTH, BUTTON_HEIGHT)
             .tooltip(Tooltip.create(Component.translatable("atm10_pmmo.skills_button.tooltip")))
             .build();

            event.addListener(button);
        }
    }

    // Button action handler to open Pufferfish Skills screen
    private void openPufferfishSkillsScreen() {
        var client = SkillsClientMod .getInstance();

        client.openScreen(Optional.empty());
    }

    static class SkillsButton extends ImageButton {
        private static final ResourceLocation SKILLS_BUTTON_TEXTURE = ResourceLocation.parse(RPGMod.MODID + ":textures/gui/skills_button.png");
        private static final ResourceLocation SKILLS_BUTTON_TEXTURE_PRESSED = ResourceLocation.parse(RPGMod.MODID + ":textures/gui/skills_button_pressed.png");
        //private static final ResourceLocation SKILLS_BUTTON_TEXTURE_DISABLED = ResourceLocation.parse(RPGMod.MODID + ":textures/gui/skills_button_disabled.png");
        private static final WidgetSprites SPRITES = new WidgetSprites(SKILLS_BUTTON_TEXTURE, SKILLS_BUTTON_TEXTURE_PRESSED);

        public SkillsButton(int x, int y, int width, int height, OnPress onPress, Component message) {
            super(x, y, width, height, SPRITES, (b) -> {
                SkillsClientMod .getInstance().openScreen(Optional.empty());
             });
        }
    }
}
