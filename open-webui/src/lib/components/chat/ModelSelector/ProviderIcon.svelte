<script lang="ts">
	// Ícone de marca do provedor (chip flat com bevel via .mh-prov-icon no custom.css).
	// Marcas dos majors portadas do host (HubIaView.jsx); long-tail = lettermark limpo.
	export let provider: string = 'other';

	const BG: Record<string, string> = {
		openai: '#000000',
		anthropic: '#D97757',
		google: '#ffffff',
		xai: '#000000',
		deepseek: '#4D6BFE',
		meta: '#0866FF',
		mistral: '#000000',
		perplexity: '#20808D',
		qwen: '#615CED',
		minimax: '#E8391F',
		zhipu: '#3A5CF6',
		moonshot: '#16101E',
		nemotron: '#76B900',
		cohere: '#39594D',
		other: 'var(--nh-panel-2)'
	};

	const LETTERS: Record<string, string> = {
		qwen: 'Qw',
		minimax: 'M',
		zhipu: 'GLM',
		moonshot: 'K',
		nemotron: 'N',
		cohere: 'C'
	};

	$: bg = BG[provider] ?? BG.other;
	$: letters = LETTERS[provider];
</script>

<span class="mh-prov-icon" style="background:{bg};{provider === 'google' ? 'border:1px solid var(--nh-border);' : ''}">
	{#if provider === 'openai'}
		<svg viewBox="0 0 28 28" fill="none" stroke="#fff" stroke-width="1.6" aria-hidden="true">
			<ellipse cx="14" cy="14" rx="4.6" ry="10" />
			<ellipse cx="14" cy="14" rx="4.6" ry="10" transform="rotate(60 14 14)" />
			<ellipse cx="14" cy="14" rx="4.6" ry="10" transform="rotate(120 14 14)" />
		</svg>
	{:else if provider === 'anthropic'}
		<svg viewBox="0 0 28 28" stroke="#fff" stroke-width="2.4" stroke-linecap="round" aria-hidden="true">
			<path d="M14 5v18M5 14h18M7.7 7.7l12.6 12.6M20.3 7.7L7.7 20.3" />
		</svg>
	{:else if provider === 'google'}
		<svg viewBox="0 0 28 28" aria-hidden="true">
			<path
				d="M14 3c.6 6 4.8 10.4 11 11-6.2.6-10.4 5-11 11-.6-6-4.8-10.4-11-11C9.2 13.4 13.4 9 14 3Z"
				fill="#4285F4"
			/>
		</svg>
	{:else if provider === 'xai'}
		<svg viewBox="0 0 28 28" stroke="#fff" stroke-width="2.4" stroke-linecap="round" aria-hidden="true">
			<path d="M8 22 18.5 7M13.5 22 22 10M6 12 10 6" />
		</svg>
	{:else if provider === 'meta'}
		<svg viewBox="0 0 28 28" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" aria-hidden="true">
			<path
				d="M4 14c0-4 2.4-6.5 5-6.5 3.6 0 5 6.5 5 6.5s1.4 6.5 5 6.5c2.6 0 5-2.5 5-6.5s-2.4-6.5-5-6.5c-3.6 0-5 6.5-5 6.5s-1.4 6.5-5 6.5C6.4 20.5 4 18 4 14Z"
			/>
		</svg>
	{:else if provider === 'mistral'}
		<svg viewBox="0 0 28 28" aria-hidden="true">
			<rect x="5" y="6.5" width="18" height="4.3" fill="#FFD800" />
			<rect x="5" y="11.85" width="18" height="4.3" fill="#FF8205" />
			<rect x="5" y="17.2" width="18" height="4.3" fill="#FA500F" />
		</svg>
	{:else if provider === 'deepseek'}
		<svg viewBox="0 0 28 28" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round" aria-hidden="true">
			<path d="M5 15c3.5-6 10-8 15.5-6.5C17 9 13 12 13 16c3.5-1 6.5.5 8 3" />
			<circle cx="19.5" cy="9.5" r="1" fill="#fff" stroke="none" />
		</svg>
	{:else if provider === 'perplexity'}
		<svg viewBox="0 0 28 28" fill="none" stroke="#fff" stroke-width="1.9" stroke-linecap="round" aria-hidden="true">
			<path d="M14 5v18" />
			<path d="M6.5 9A9 9 0 0 1 21.5 9" />
			<path d="M6.5 19A9 9 0 0 0 21.5 19" />
		</svg>
	{:else if letters}
		<span class="mh-prov-letter">{letters}</span>
	{:else}
		<!-- 'other'/desconhecido: glifo neutro em tinta (chip claro) -->
		<svg viewBox="0 0 24 24" fill="none" stroke="var(--nh-ink-2)" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
			<path d="M12 3l2.2 5.3L20 10.5l-5 3.2L16 20l-4-3.3L8 20l1-6.3-5-3.2 5.8-2.2L12 3Z" />
		</svg>
	{/if}
</span>

<style>
	.mh-prov-letter {
		color: #fff;
		font-weight: 700;
		font-size: 11px;
		letter-spacing: -0.02em;
		line-height: 1;
	}
</style>
