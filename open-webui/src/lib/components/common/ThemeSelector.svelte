<script lang="ts">
	import { DropdownMenu } from 'bits-ui';
	import { getContext, onMount } from 'svelte';
	import { fade } from 'svelte/transition';

	import { theme, settings } from '$lib/stores';
	import Tooltip from '$lib/components/common/Tooltip.svelte';

	const i18n = getContext('i18n');

	let show = false;
	let themes = ['dark', 'light', 'oled-dark'];
	let selectedTheme = 'system';

	onMount(() => {
		selectedTheme = localStorage.theme ?? 'system';
	});

	const applyTheme = (_theme: string) => {
		let themeToApply = _theme === 'oled-dark' ? 'dark' : _theme === 'her' ? 'light' : _theme;

		if (_theme === 'system') {
			themeToApply = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
		}

		if (themeToApply === 'dark' && !_theme.includes('oled')) {
			document.documentElement.style.setProperty('--color-gray-800', '#333');
			document.documentElement.style.setProperty('--color-gray-850', '#262626');
			document.documentElement.style.setProperty('--color-gray-900', '#171717');
			document.documentElement.style.setProperty('--color-gray-950', '#0d0d0d');
		}

		themes
			.filter((e) => e !== themeToApply)
			.forEach((e) => {
				e.split(' ').forEach((e) => {
					document.documentElement.classList.remove(e);
				});
			});

		themeToApply.split(' ').forEach((e) => {
			document.documentElement.classList.add(e);
		});

		const metaThemeColor = document.querySelector('meta[name="theme-color"]');
		if (metaThemeColor) {
			if (_theme.includes('system')) {
				const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches
					? 'dark'
					: 'light';
				metaThemeColor.setAttribute('content', systemTheme === 'light' ? '#ffffff' : '#171717');
			} else {
				metaThemeColor.setAttribute(
					'content',
					_theme === 'dark'
						? '#171717'
						: _theme === 'oled-dark'
							? '#000000'
							: _theme === 'her'
								? '#983724'
								: '#ffffff'
				);
			}
		}

		if (typeof window !== 'undefined' && window.applyTheme) {
			window.applyTheme();
		}

		if (_theme.includes('oled')) {
			document.documentElement.style.setProperty('--color-gray-800', '#101010');
			document.documentElement.style.setProperty('--color-gray-850', '#050505');
			document.documentElement.style.setProperty('--color-gray-900', '#000000');
			document.documentElement.style.setProperty('--color-gray-950', '#000000');
			document.documentElement.classList.add('dark');
		}
	};

	const themeChangeHandler = (_theme: string) => {
		selectedTheme = _theme;
		theme.set(_theme);
		localStorage.setItem('theme', _theme);
		applyTheme(_theme);
		show = false;
	};

	const getThemeIcon = (themeName: string) => {
		switch (themeName) {
			case 'system':
				return '⚙️';
			case 'dark':
				return '🌑';
			case 'oled-dark':
				return '🌃';
			case 'light':
				return '☀️';
			case 'her':
				return '🌷';
			default:
				return '⚙️';
		}
	};
</script>

<DropdownMenu.Root bind:open={show}>
	<DropdownMenu.Trigger>
		<Tooltip content={$i18n.t('Theme')}>
			<button
				class="flex cursor-pointer px-2 py-2 rounded-xl hover:bg-gray-50 dark:hover:bg-gray-850 transition"
				aria-label={$i18n.t('Theme')}
			>
				<div class="m-auto self-center">
					{#if selectedTheme === 'light'}
						<!-- Sun icon -->
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
					{:else if selectedTheme === 'dark' || selectedTheme === 'oled-dark'}
						<!-- Moon icon -->
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
						<!-- System/Computer icon -->
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
								d="M9 17.25v1.007a3 3 0 0 1-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0 1 15 18.257V17.25m6-12V15a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 15V5.25m18 0A2.25 2.25 0 0 0 18.75 3H5.25A2.25 2.25 0 0 0 3 5.25m18 0V12a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 12V5.25"
							/>
						</svg>
					{/if}
				</div>
			</button>
		</Tooltip>
	</DropdownMenu.Trigger>

	<DropdownMenu.Content
		class="w-full max-w-[160px] rounded-2xl px-1 py-1 border border-gray-100 dark:border-gray-800 z-50 bg-white dark:bg-gray-850 dark:text-white shadow-lg text-sm"
		sideOffset={4}
		side="bottom"
		align="end"
		transition={(e) => fade(e, { duration: 100 })}
	>
		<DropdownMenu.Item
			class="flex gap-2 items-center px-3 py-1.5 text-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 rounded-xl select-none w-full {selectedTheme ===
			'system'
				? 'bg-gray-100 dark:bg-gray-800'
				: ''}"
			on:click={() => themeChangeHandler('system')}
		>
			<span>⚙️</span>
			<span>{$i18n.t('System')}</span>
		</DropdownMenu.Item>

		<DropdownMenu.Item
			class="flex gap-2 items-center px-3 py-1.5 text-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 rounded-xl select-none w-full {selectedTheme ===
			'dark'
				? 'bg-gray-100 dark:bg-gray-800'
				: ''}"
			on:click={() => themeChangeHandler('dark')}
		>
			<span>🌑</span>
			<span>{$i18n.t('Dark')}</span>
		</DropdownMenu.Item>

		<DropdownMenu.Item
			class="flex gap-2 items-center px-3 py-1.5 text-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 rounded-xl select-none w-full {selectedTheme ===
			'oled-dark'
				? 'bg-gray-100 dark:bg-gray-800'
				: ''}"
			on:click={() => themeChangeHandler('oled-dark')}
		>
			<span>🌃</span>
			<span>{$i18n.t('OLED Dark')}</span>
		</DropdownMenu.Item>

		<DropdownMenu.Item
			class="flex gap-2 items-center px-3 py-1.5 text-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 rounded-xl select-none w-full {selectedTheme ===
			'light'
				? 'bg-gray-100 dark:bg-gray-800'
				: ''}"
			on:click={() => themeChangeHandler('light')}
		>
			<span>☀️</span>
			<span>{$i18n.t('Light')}</span>
		</DropdownMenu.Item>

		<DropdownMenu.Item
			class="flex gap-2 items-center px-3 py-1.5 text-sm cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800 rounded-xl select-none w-full {selectedTheme ===
			'her'
				? 'bg-gray-100 dark:bg-gray-800'
				: ''}"
			on:click={() => themeChangeHandler('her')}
		>
			<span>🌷</span>
			<span>Her</span>
		</DropdownMenu.Item>
	</DropdownMenu.Content>
</DropdownMenu.Root>

