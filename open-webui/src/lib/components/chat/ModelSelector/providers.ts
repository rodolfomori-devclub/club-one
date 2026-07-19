/*
 * MasiHub — agrupamento do seletor de modelos por LLM (provedor) → versão,
 * no estilo adapta.org. Deriva provedor/versão/badge no front, sem backend.
 *
 * Espelha (e estende) o PROVIDER_PATTERNS do backend
 * (backend/open_webui/routers/models.py) para que o agrupamento do UI e o
 * avatar server-side (/models/model/profile/image) concordem. Tolera ids
 * "bare" (gpt-4o), "slashed" (openai/gpt-4o) e "prefixed" (conn.openai/gpt-4o).
 */

export type ProviderId =
	| 'openai'
	| 'anthropic'
	| 'google'
	| 'xai'
	| 'deepseek'
	| 'perplexity'
	| 'meta'
	| 'mistral'
	| 'cohere'
	| 'qwen'
	| 'minimax'
	| 'zhipu'
	| 'moonshot'
	| 'nemotron'
	| 'other';

export interface Badge {
	variant: 'new' | 'hot' | 'featured' | 'custom';
	label: string;
}

export interface VersionEntry {
	value: string;
	label: string; // nome completo cru (fallback)
	version: string; // nome amigável COM marca (ex.: "Llama 4 Maverick")
	variant: string; // nome amigável SEM marca (ex.: "Sonnet 5") — usado no flyout
	badge: Badge | null;
	descriptor: string | null;
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	model: any;
}

export interface ProviderGroup {
	provider: ProviderId;
	label: string;
	single: boolean;
	models: VersionEntry[];
}

export interface ModelGroups {
	featured: VersionEntry[];
	providers: ProviderGroup[];
}

export interface BuildCtx {
	defaultModels?: string[];
	pinnedModels?: string[];
	t?: (key: string) => string;
}

// Ordem importa: específico antes de genérico; 'meta' por último ('llama').
const PROVIDER_PATTERNS: [ProviderId, string[]][] = [
	['openai', ['gpt-', 'gpt.', 'gpt4', 'o1-', 'o1.', 'o3-', 'o3.', 'o4-', 'chatgpt', 'openai/', 'dall-e']],
	['anthropic', ['claude', 'anthropic/']],
	['google', ['gemini', 'google/', 'gemma', 'palm', 'bison']],
	['xai', ['grok', 'xai/', 'x-ai/']],
	['deepseek', ['deepseek']],
	['perplexity', ['perplexity', 'sonar', 'pplx']],
	['cohere', ['command-', 'command.', 'cohere/', 'c4ai', 'aya']],
	['mistral', ['mistral', 'mixtral', 'ministral', 'magistral', 'codestral', 'pixtral', 'devstral']],
	['qwen', ['qwen', 'qwq', 'tongyi', 'alibaba/']],
	['minimax', ['minimax', 'abab']],
	['zhipu', ['glm-', 'glm.', 'glm4', 'chatglm', 'zhipu', 'z-ai/', 'thudm/', 'bigmodel']],
	['moonshot', ['kimi', 'moonshot']],
	['nemotron', ['nemotron', 'nvidia/']],
	['meta', ['llama', 'meta/', 'meta-llama']]
];

export const PROVIDER_LABELS: Record<ProviderId, string> = {
	openai: 'GPT',
	anthropic: 'Claude',
	google: 'Gemini',
	xai: 'Grok',
	deepseek: 'DeepSeek',
	perplexity: 'Perplexity',
	meta: 'Llama',
	mistral: 'Mistral',
	cohere: 'Command',
	qwen: 'Qwen',
	minimax: 'MiniMax',
	zhipu: 'GLM',
	moonshot: 'Kimi',
	nemotron: 'Nemotron',
	other: 'Outros'
};

// Tokens da marca a remover no nome amigável "sem marca" (flyout).
const PROVIDER_BRAND_TOKENS: Record<ProviderId, string[]> = {
	openai: ['gpt', 'openai', 'chatgpt', 'o1', 'o3', 'o4'],
	anthropic: ['claude', 'anthropic'],
	google: ['gemini', 'google', 'gemma', 'palm', 'bison'],
	xai: ['grok', 'xai', 'x'],
	deepseek: ['deepseek'],
	perplexity: ['perplexity', 'pplx'],
	meta: ['llama', 'meta'],
	mistral: ['mistral', 'mixtral'],
	cohere: ['command', 'cohere', 'c4ai'],
	qwen: ['qwen', 'tongyi'],
	minimax: ['minimax', 'abab'],
	zhipu: ['glm', 'zhipu', 'chatglm', 'z', 'ai', 'thudm'],
	moonshot: ['kimi', 'moonshot', 'moonshotai'],
	nemotron: ['nemotron', 'nvidia'],
	other: []
};

const PROVIDER_ORDER: ProviderId[] = [
	'openai',
	'anthropic',
	'google',
	'deepseek',
	'xai',
	'meta',
	'qwen',
	'moonshot',
	'minimax',
	'zhipu',
	'perplexity',
	'nemotron',
	'mistral',
	'cohere',
	'other'
];

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function deriveProvider(model: any): ProviderId {
	const hay = `${model?.id ?? ''} ${model?.name ?? ''}`.toLowerCase();
	for (const [pid, pats] of PROVIDER_PATTERNS) {
		if (pats.some((p) => hay.includes(p))) return pid;
	}
	return 'other';
}

const BRAND_CASE: Record<string, string> = {
	gpt: 'GPT',
	glm: 'GLM',
	ai: 'AI',
	xai: 'xAI',
	minimax: 'MiniMax',
	deepseek: 'DeepSeek',
	llama: 'Llama',
	qwen: 'Qwen',
	qwq: 'QwQ',
	kimi: 'Kimi',
	mistral: 'Mistral',
	mixtral: 'Mixtral',
	gemini: 'Gemini',
	gemma: 'Gemma',
	claude: 'Claude',
	grok: 'Grok',
	nemotron: 'Nemotron',
	command: 'Command',
	perplexity: 'Perplexity',
	sonar: 'Sonar',
	sonnet: 'Sonnet',
	opus: 'Opus',
	haiku: 'Haiku'
};

function lastSeg(id: string): string {
	const i = id.lastIndexOf('/');
	return i >= 0 ? id.slice(i + 1) : id;
}

function titleTok(tok: string): string {
	const low = tok.toLowerCase();
	if (BRAND_CASE[low]) return BRAND_CASE[low];
	if (/\d/.test(tok)) return /^[a-z]/i.test(tok) ? tok.charAt(0).toUpperCase() + tok.slice(1) : tok; // v3 -> V3? mantém dígitos
	return tok.charAt(0).toUpperCase() + tok.slice(1);
}

// Rótulo humano COM a marca (ex.: "Llama 4 Maverick", "Claude 4.6 Sonnet").
// Nome curado (com espaço/caixa mista) é usado como está.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function humanVersion(model: any): string {
	const name = String(model?.name ?? '').trim();
	if (name && (/\s/.test(name) || (/[a-z]/.test(name) && /[A-Z]/.test(name)))) return name;

	let base = name || lastSeg(String(model?.id ?? ''));
	base = lastSeg(base);
	base = base.replace(/^[a-z0-9]+\./i, '');
	if (!base) return name || String(model?.id ?? '');

	const parts = base
		.split(/[-_\s]+/)
		.filter(Boolean)
		.filter((tok) => !/^\d{6,}$/.test(tok));

	return parts.map(titleTok).join(' ') || base;
}

// Rótulo amigável SEM a marca, ordenado variante→número, sem "-"
// (ex.: "Sonnet 5", "Opus 4.8", "Flash 3.5"). Usado nos itens do flyout.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function friendlyVariant(model: any, provider: ProviderId): string {
	let base = String(model?.name ?? '').trim() || lastSeg(String(model?.id ?? ''));
	base = lastSeg(base).replace(/^[a-z0-9]+\./i, '');

	const brand = new Set((PROVIDER_BRAND_TOKENS[provider] ?? []).map((x) => x.toLowerCase()));
	let toks = base
		.split(/[-_\s/]+/)
		.filter(Boolean)
		.filter((t) => !/^\d{6,}$/.test(t))
		.filter((t) => !brand.has(t.toLowerCase()));

	const alpha = toks.filter((t) => !/\d/.test(t)).map(titleTok);
	const nums = toks.filter((t) => /\d/.test(t)).map((t) => (/^[a-z]/i.test(t) ? t.charAt(0).toUpperCase() + t.slice(1) : t));

	const label = [...alpha, ...nums].join(' ').trim();
	return label || humanVersion(model);
}

const BADGE_KEY: Record<'new' | 'hot' | 'featured', string> = {
	new: 'New',
	hot: 'Trending',
	featured: 'Highlighted'
};

const BADGE_RULES: { re: RegExp; variant: 'new' | 'hot' }[] = [];

export function deriveBadge(
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	model: any,
	ctx: BuildCtx & { t: (key: string) => string }
): Badge | null {
	const meta = model?.info?.meta ?? {};
	if (meta.badge) {
		if (typeof meta.badge === 'string') return { variant: 'custom', label: meta.badge };
		if (meta.badge.label) return { variant: meta.badge.variant ?? 'custom', label: meta.badge.label };
	}
	const id = String(model?.id ?? '');
	if ((ctx.defaultModels ?? []).includes(id)) return { variant: 'featured', label: ctx.t(BADGE_KEY.featured) };

	const hay = `${id} ${model?.name ?? ''}`.toLowerCase();
	for (const rule of BADGE_RULES) {
		if (rule.re.test(hay)) return { variant: rule.variant, label: ctx.t(BADGE_KEY[rule.variant]) };
	}
	return null;
}

export function deriveDescriptor(
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	model: any,
	ctx: { t: (key: string) => string }
): string | null {
	const meta = model?.info?.meta ?? {};
	if (meta.descriptor) return String(meta.descriptor);
	// \b evita falso-positivo por substring (ex.: "mini" dentro de "geMINI").
	const hay = `${model?.id ?? ''} ${model?.name ?? ''}`.toLowerCase();
	if (/\b(haiku|flash|mini|lite|fast|turbo|nano|small|air|instant)\b/.test(hay)) return ctx.t('Faster');
	if (/\b(opus|ultra|max|pro|large|heavy|thinking|reasoner|reason)\b/.test(hay)) return ctx.t('More capable');
	return null;
}

interface Item {
	value: string;
	label: string;
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	model: any;
}

export function buildModelGroups(items: Item[], ctx: BuildCtx = {}): ModelGroups {
	const t = ctx.t ?? ((k: string) => k);
	const c = { ...ctx, t };

	const visible = (items ?? []).filter((it) => !(it?.model?.info?.meta?.hidden ?? false));
	const defaults = (ctx.defaultModels ?? []).filter(Boolean);
	const pinned = new Set(ctx.pinnedModels ?? []);
	const featuredSet = new Set(defaults);

	const toEntry = (it: Item, provider: ProviderId, useFullName = false): VersionEntry => ({
		value: it.value,
		label: it.label,
		version: useFullName ? it.model?.name || it.label : humanVersion(it.model),
		variant: friendlyVariant(it.model, provider),
		badge: deriveBadge(it.model, c),
		descriptor: deriveDescriptor(it.model, c),
		model: it.model
	});

	const featured: VersionEntry[] = defaults
		.map((id) => visible.find((it) => it.value === id))
		.filter((it): it is Item => Boolean(it))
		.map((it) => toEntry(it, deriveProvider(it.model), true));

	const rest = visible.filter((it) => !featuredSet.has(it.value));
	const buckets = new Map<ProviderId, VersionEntry[]>();
	for (const it of rest) {
		const pid = deriveProvider(it.model);
		if (!buckets.has(pid)) buckets.set(pid, []);
		(buckets.get(pid) as VersionEntry[]).push(toEntry(it, pid));
	}

	const numOf = (e: VersionEntry): number => {
		const m = `${e.version} ${e.model?.id ?? ''}`.match(/(\d+(?:\.\d+)?)/);
		return m ? parseFloat(m[1]) : -1;
	};

	const providers: ProviderGroup[] = [];
	for (const [pid, entries] of buckets) {
		entries.sort((a, b) => {
			const pa = pinned.has(a.value) ? 1 : 0;
			const pb = pinned.has(b.value) ? 1 : 0;
			if (pa !== pb) return pb - pa;
			return numOf(b) - numOf(a);
		});
		providers.push({
			provider: pid,
			label: PROVIDER_LABELS[pid],
			single: entries.length === 1,
			models: entries
		});
	}

	providers.sort((a, b) => {
		const ia = PROVIDER_ORDER.indexOf(a.provider);
		const ib = PROVIDER_ORDER.indexOf(b.provider);
		const ra = ia < 0 ? 999 : ia;
		const rb = ib < 0 ? 999 : ib;
		if (ra !== rb) return ra - rb;
		return a.label.localeCompare(b.label);
	});

	return { featured, providers };
}
