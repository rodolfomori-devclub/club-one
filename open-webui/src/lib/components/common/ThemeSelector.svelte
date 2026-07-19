<script lang="ts">
	import { getContext, onMount } from 'svelte';

	import { theme } from '$lib/stores';
	import Tooltip from '$lib/components/common/Tooltip.svelte';

	const i18n = getContext('i18n');

	// ClubHub: apenas claro/escuro — toggle simples no ícone (sem menu).
	let selectedTheme = 'light';

	onMount(() => {
		const t = localStorage.theme;
		selectedTheme = t === 'dark' || t === 'oled-dark' ? 'dark' : 'light';
	});

	const applyTheme = (_theme: string) => {
		const dark = _theme === 'dark';

		if (dark) {
			document.documentElement.style.setProperty('--color-gray-800', '#333');
			document.documentElement.style.setProperty('--color-gray-850', '#262626');
			document.documentElement.style.setProperty('--color-gray-900', '#171717');
			document.documentElement.style.setProperty('--color-gray-950', '#0d0d0d');
		}

		document.documentElement.classList.remove('dark', 'light', 'oled-dark', 'her', 'system');
		document.documentElement.classList.add(dark ? 'dark' : 'light');
		document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');

		const metaThemeColor = document.querySelector('meta[name="theme-color"]');
		if (metaThemeColor) {
			metaThemeColor.setAttribute('content', dark ? '#171717' : '#ffffff');
		}

		if (typeof window !== 'undefined' && window.applyTheme) {
			window.applyTheme();
		}
	};

	const toggleTheme = () => {
		selectedTheme = selectedTheme === 'dark' ? 'light' : 'dark';
		theme.set(selectedTheme);
		localStorage.setItem('theme', selectedTheme);
		applyTheme(selectedTheme);
	};
</script>

<Tooltip content={$i18n.t('Theme')}>
	<button
		class="flex cursor-pointer px-2 py-2 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-850 transition"
		aria-label={$i18n.t('Theme')}
		on:click={toggleTheme}
	>
		<div class="m-auto self-center">
			{#if selectedTheme === 'dark'}
				<!-- Moon icon (tema escuro ativo — clique volta pro claro) -->
				<svg
					xmlns="http://www.w3.org/2000/svg"
					fill="none"
					viewBox="0 0 24 24"
					stroke-width="1.5"
					stroke="currentColor"
					class="size-4.5"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z"
					/>
				</svg>
			{:else}
				<!-- Sun icon (tema claro ativo — clique vai pro escuro) -->
				<svg
					xmlns="http://www.w3.org/2000/svg"
					fill="none"
					viewBox="0 0 24 24"
					stroke-width="1.5"
					stroke="currentColor"
					class="size-4.5"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z"
					/>
				</svg>
			{/if}
		</div>
	</button>
</Tooltip>
