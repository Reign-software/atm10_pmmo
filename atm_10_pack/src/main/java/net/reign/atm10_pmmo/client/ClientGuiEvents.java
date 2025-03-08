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
/*
import net.reign.atm10_pmmo.RPGMod;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.client.gui.components.ImageButton;
import net.minecraft.client.gui.components.WidgetSprites;
*/

public class ClientGuiEvents {
    
    // Position of your button
    private static final int BUTTON_X_POS = 275; // Adjust as needed
    private static final int BUTTON_Y_POS = 5;   // Adjust as needed

    /*
    private static final int BUTTON_WIDTH = 15;
    private static final int BUTTON_HEIGHT = 15;
    
    private static final ResourceLocation SKILLS_BUTTON_TEXTURE = ResourceLocation.parse(RPGMod.MODID + ":textures/gui/skills_button.png");
    private static final ResourceLocation SKILLS_BUTTON_TEXTURE_PRESSED = ResourceLocation.parse(RPGMod.MODID + ":textures/gui/skills_button_pressed.png");
    private static final ResourceLocation SKILLS_BUTTON_TEXTURE_DISABLED = ResourceLocation.parse(RPGMod.MODID + ":textures/gui/skills_button_disabled.png");
    */
    @OnlyIn(Dist.CLIENT)
    @SubscribeEvent
    public void onGuiInit(ScreenEvent.Init.Pre event) {
        if (event.getScreen() instanceof InventoryScreen) {
            /*
            // enabled, disabled, enabled focused, disabled focused
            var button = new WidgetSprites(SKILLS_BUTTON_TEXTURE, SKILLS_BUTTON_TEXTURE_DISABLED, SKILLS_BUTTON_TEXTURE_PRESSED, SKILLS_BUTTON_TEXTURE_DISABLED);

            // Add a button with a skills icon
            event.addListener(new ImageButton(
                BUTTON_X_POS, BUTTON_Y_POS, BUTTON_HEIGHT, BUTTON_WIDTH,  // x, y, width, height
                button,
                (b) -> {
                    openPufferfishSkillsScreen();
                },
                Component.translatable("atm10_pmmo.skills_button.tooltip")
            ));
             */

             var button = Button.builder(Component.translatable("atm10_pmmo.skills_button.tooltip"), (b) -> {
                openPufferfishSkillsScreen();
             })
             .pos(BUTTON_X_POS, BUTTON_Y_POS)
             .build();

            event.addListener(button);
        }
    }

    // Button action handler to open Pufferfish Skills screen
    private void openPufferfishSkillsScreen() {
        var client = SkillsClientMod .getInstance();

        client.openScreen(Optional.empty());
    }
}
