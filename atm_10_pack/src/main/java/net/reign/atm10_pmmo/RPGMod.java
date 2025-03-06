package net.reign.atm10_pmmo;

import org.apache.logging.log4j.Logger;

import dev.ftb.mods.ftbultimine.integration.FTBUltiminePlugin;

import org.apache.logging.log4j.LogManager;

import net.neoforged.neoforge.network.registration.PayloadRegistrar;
import net.reign.atm10_pmmo.client.ClientGuiEvents;
import net.reign.atm10_pmmo.client.FTBUltimine;
import net.neoforged.neoforge.network.handling.IPayloadHandler;
import net.neoforged.neoforge.network.event.RegisterPayloadHandlersEvent;
import net.neoforged.neoforge.event.tick.ServerTickEvent;
import net.neoforged.neoforge.common.ModConfigSpec;
import net.neoforged.neoforge.common.NeoForge;
import net.neoforged.fml.util.thread.SidedThreadGroups;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.ModList;
import net.neoforged.bus.api.SubscribeEvent;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.fml.loading.FMLEnvironment;

import net.minecraft.util.Tuple;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.FriendlyByteBuf;

import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.Map;
import java.util.List;
import java.util.HashMap;
import java.util.Collection;
import java.util.ArrayList;

@Mod("atm10_pmmo")
public class RPGMod {
	public static final Logger LOGGER = LogManager.getLogger(RPGMod.class);
	public static final String MODID = "atm10_pmmo";

	public RPGMod(IEventBus modEventBus) {
		// Start of user code block mod constructor
		LOGGER.info("Initializing Project MMO ATM10 Integration");
		
		// Note: Config is now managed by Jade itself
		// Check if Jade is loaded
		if (ModList.get().isLoaded("jade")) {
			LOGGER.info("Jade is loaded, registering PMMO integration");
		}

		// Check if PMMO is loaded
		if (ModList.get().isLoaded("pmmo")) {
			LOGGER.info("PMMO is loaded, integration available");
		} else {
			LOGGER.warn("PMMO is not loaded! Integration will not function.");
		}

		if (ModList.get().isLoaded("puffish_skills")) {
			LOGGER.info("Pufferfish Skills is loaded, integration available");
		} else {
			LOGGER.warn("Pufferfish Skills is not loaded! Integration will not function.");
		}
		
		// Register client events if we're on the client side
		if (FMLEnvironment.dist == Dist.CLIENT) {
			LOGGER.info("Registering client GUI events");
			NeoForge.EVENT_BUS.register(new ClientGuiEvents());
		}
		// End of user code block mod constructor
		NeoForge.EVENT_BUS.register(this);
		NeoForge.EVENT_BUS.addListener(PufferfishLevelPlugin::XpGainedEvent);
		modEventBus.addListener(this::registerNetworking);
		
		FTBUltiminePlugin.register(new FTBUltimine());
		// Start of user code block mod init
		// End of user code block mod init
	}

	// Start of user code block mod methods
	// End of user code block mod methods
	private static boolean networkingRegistered = false;
	private static final Map<CustomPacketPayload.Type<?>, NetworkMessage<?>> MESSAGES = new HashMap<>();

	private record NetworkMessage<T extends CustomPacketPayload>(StreamCodec<? extends FriendlyByteBuf, T> reader, IPayloadHandler<T> handler) {
	}

	public static <T extends CustomPacketPayload> void addNetworkMessage(CustomPacketPayload.Type<T> id, StreamCodec<? extends FriendlyByteBuf, T> reader, IPayloadHandler<T> handler) {
		if (networkingRegistered)
			throw new IllegalStateException("Cannot register new network messages after networking has been registered");
		MESSAGES.put(id, new NetworkMessage<>(reader, handler));
	}

	@SuppressWarnings({"rawtypes", "unchecked"})
	private void registerNetworking(final RegisterPayloadHandlersEvent event) {
		final PayloadRegistrar registrar = event.registrar(MODID);
		MESSAGES.forEach((id, networkMessage) -> registrar.playBidirectional(id, ((NetworkMessage) networkMessage).reader(), ((NetworkMessage) networkMessage).handler()));
		networkingRegistered = true;
	}

	private static final Collection<Tuple<Runnable, Integer>> workQueue = new ConcurrentLinkedQueue<>();

	public static void queueServerWork(int tick, Runnable action) {
		if (Thread.currentThread().getThreadGroup() == SidedThreadGroups.SERVER)
			workQueue.add(new Tuple<>(action, tick));
	}

	@SubscribeEvent
	public void tick(ServerTickEvent.Post event) {
		List<Tuple<Runnable, Integer>> actions = new ArrayList<>();
		workQueue.forEach(work -> {
			work.setB(work.getB() - 1);
			if (work.getB() == 0)
				actions.add(work);
		});
		actions.forEach(e -> e.getA().run());
		workQueue.removeAll(actions);
	}
}
