import * as React from 'react'
import { Plus, Pencil, Search, Upload, Loader2 } from 'lucide-react'
import { supabase } from '@/lib/supabase'
import { uploadImage } from '@/lib/storage'
import { PageHeader } from '@/components/Layout'
import {
  Button,
  Badge,
  Input,
  Select,
  Modal,
  Card,
} from '@/components/ui/primitives'
import type { Tables, TablesInsert } from '@/lib/database.types'
import { formatMoney } from '@/lib/utils'

type Product = Tables<'products'>
type Category = Tables<'categories'>

const EMPTY: TablesInsert<'products'> = {
  category_id: '',
  name_ar: '',
  name_en: '',
  description_ar: '',
  description_en: '',
  image_url: null,
  base_price: 0,
  calories: null,
  is_active: true,
  sort_order: 0,
}

export default function Products() {
  const [products, setProducts] = React.useState<Product[]>([])
  const [categories, setCategories] = React.useState<Category[]>([])
  const [search, setSearch] = React.useState('')
  const [catFilter, setCatFilter] = React.useState('')
  const [modalOpen, setModalOpen] = React.useState(false)
  const [editing, setEditing] = React.useState<Product | null>(null)
  const [form, setForm] = React.useState<TablesInsert<'products'>>(EMPTY)
  const [saving, setSaving] = React.useState(false)
  const [uploading, setUploading] = React.useState(false)
  const [uploadError, setUploadError] = React.useState<string | null>(null)

  async function onPickImage(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    setUploadError(null)
    setUploading(true)
    try {
      const url = await uploadImage('product-images', file)
      setForm((f) => ({ ...f, image_url: url }))
    } catch (err) {
      setUploadError(err instanceof Error ? err.message : 'تعذّر رفع الصورة')
    } finally {
      setUploading(false)
      e.target.value = ''
    }
  }

  const load = React.useCallback(async () => {
    const [{ data: p }, { data: c }] = await Promise.all([
      supabase.from('products').select('*').order('sort_order'),
      supabase.from('categories').select('*').order('sort_order'),
    ])
    setProducts(p ?? [])
    setCategories(c ?? [])
  }, [])

  React.useEffect(() => {
    load()
  }, [load])

  const catName = (id: string) =>
    categories.find((c) => c.id === id)?.name_ar ?? '—'

  function openNew() {
    setEditing(null)
    setForm({ ...EMPTY, category_id: categories[0]?.id ?? '' })
    setModalOpen(true)
  }

  function openEdit(p: Product) {
    setEditing(p)
    setForm({
      category_id: p.category_id,
      name_ar: p.name_ar,
      name_en: p.name_en,
      description_ar: p.description_ar ?? '',
      description_en: p.description_en ?? '',
      image_url: p.image_url,
      base_price: p.base_price,
      calories: p.calories,
      is_active: p.is_active,
      sort_order: p.sort_order,
    })
    setModalOpen(true)
  }

  async function save(e: React.FormEvent) {
    e.preventDefault()
    setSaving(true)
    if (editing) {
      await supabase.from('products').update(form).eq('id', editing.id)
    } else {
      await supabase.from('products').insert(form)
    }
    setSaving(false)
    setModalOpen(false)
    load()
  }

  async function toggleActive(p: Product) {
    await supabase
      .from('products')
      .update({ is_active: !p.is_active })
      .eq('id', p.id)
    load()
  }

  const filtered = products.filter((p) => {
    const matchCat = !catFilter || p.category_id === catFilter
    const q = search.trim().toLowerCase()
    const matchSearch =
      !q ||
      p.name_ar.toLowerCase().includes(q) ||
      p.name_en.toLowerCase().includes(q)
    return matchCat && matchSearch
  })

  return (
    <>
      <PageHeader
        title="إدارة المنتجات"
        subtitle={`${products.length} منتج`}
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" /> منتج جديد
          </Button>
        }
      />

      <div className="p-6">
        {/* Filters */}
        <div className="mb-4 flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <Input
              className="pr-9"
              placeholder="بحث بالاسم…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <Select
            value={catFilter}
            onChange={(e) => setCatFilter(e.target.value)}
            className="w-48"
          >
            <option value="">كل الأصناف</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name_ar}
              </option>
            ))}
          </Select>
        </div>

        {/* Table */}
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="bg-slate-50 text-slate-500">
                <tr>
                  <th className="px-4 py-3 font-semibold">المنتج</th>
                  <th className="px-4 py-3 font-semibold">الصنف</th>
                  <th className="px-4 py-3 font-semibold">السعر الأساسي</th>
                  <th className="px-4 py-3 font-semibold">السعرات</th>
                  <th className="px-4 py-3 font-semibold">الحالة</th>
                  <th className="px-4 py-3 font-semibold">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filtered.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/60">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="h-11 w-11 shrink-0 overflow-hidden rounded-lg bg-brand-50">
                          {p.image_url ? (
                            <img
                              src={p.image_url}
                              alt={p.name_ar}
                              className="h-full w-full object-cover"
                            />
                          ) : (
                            <div className="flex h-full w-full items-center justify-center text-lg">
                              🥤
                            </div>
                          )}
                        </div>
                        <div>
                          <div className="font-semibold text-slate-800">{p.name_ar}</div>
                          <div className="text-xs text-slate-400" dir="ltr">
                            {p.name_en}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-600">{catName(p.category_id)}</td>
                    <td className="px-4 py-3 font-semibold text-brand-700">
                      {formatMoney(p.base_price)}
                    </td>
                    <td className="px-4 py-3 text-slate-500">{p.calories ?? '—'}</td>
                    <td className="px-4 py-3">
                      <button onClick={() => toggleActive(p)}>
                        <Badge
                          className={
                            p.is_active
                              ? 'border-green-200 bg-green-50 text-green-700'
                              : 'border-slate-200 bg-slate-100 text-slate-500'
                          }
                        >
                          {p.is_active ? 'مفعّل' : 'موقوف'}
                        </Badge>
                      </button>
                    </td>
                    <td className="px-4 py-3">
                      <Button variant="ghost" size="sm" onClick={() => openEdit(p)}>
                        <Pencil className="h-4 w-4" /> تعديل
                      </Button>
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={6} className="py-10 text-center text-slate-300">
                      لا توجد منتجات مطابقة
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>

      {/* Modal */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editing ? 'تعديل منتج' : 'منتج جديد'}
      >
        <form onSubmit={save} className="space-y-4">
          {/* Image upload */}
          <Field label="صورة المنتج">
            <div className="flex items-center gap-3">
              <div className="h-20 w-20 shrink-0 overflow-hidden rounded-xl border border-slate-200 bg-brand-50">
                {form.image_url ? (
                  <img src={form.image_url} alt="" className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-2xl">🥤</div>
                )}
              </div>
              <div className="flex-1">
                <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50">
                  {uploading ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Upload className="h-4 w-4" />
                  )}
                  {uploading ? 'جارِ الرفع…' : 'رفع صورة'}
                  <input
                    type="file"
                    accept="image/*"
                    className="hidden"
                    disabled={uploading}
                    onChange={onPickImage}
                  />
                </label>
                {form.image_url && (
                  <button
                    type="button"
                    onClick={() => setForm({ ...form, image_url: null })}
                    className="mr-2 text-sm text-red-600 hover:underline"
                  >
                    إزالة
                  </button>
                )}
                {uploadError && (
                  <div className="mt-1 text-xs text-red-600">{uploadError}</div>
                )}
              </div>
            </div>
          </Field>

          <div className="grid grid-cols-2 gap-3">
            <Field label="الاسم (عربي)">
              <Input
                required
                value={form.name_ar}
                onChange={(e) => setForm({ ...form, name_ar: e.target.value })}
              />
            </Field>
            <Field label="الاسم (إنجليزي)">
              <Input
                required
                dir="ltr"
                value={form.name_en}
                onChange={(e) => setForm({ ...form, name_en: e.target.value })}
              />
            </Field>
          </div>

          <Field label="الصنف">
            <Select
              required
              value={form.category_id}
              onChange={(e) => setForm({ ...form, category_id: e.target.value })}
            >
              <option value="" disabled>
                اختر الصنف
              </option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name_ar}
                </option>
              ))}
            </Select>
          </Field>

          <div className="grid grid-cols-2 gap-3">
            <Field label="السعر الأساسي (د.ع)">
              <Input
                type="number"
                min={0}
                required
                value={form.base_price}
                onChange={(e) =>
                  setForm({ ...form, base_price: Number(e.target.value) })
                }
              />
            </Field>
            <Field label="السعرات (اختياري)">
              <Input
                type="number"
                min={0}
                value={form.calories ?? ''}
                onChange={(e) =>
                  setForm({
                    ...form,
                    calories: e.target.value ? Number(e.target.value) : null,
                  })
                }
              />
            </Field>
          </div>

          <Field label="الوصف (عربي)">
            <Input
              value={form.description_ar ?? ''}
              onChange={(e) => setForm({ ...form, description_ar: e.target.value })}
            />
          </Field>

          <label className="flex items-center gap-2 text-sm font-semibold text-slate-600">
            <input
              type="checkbox"
              className="h-4 w-4 accent-brand-600"
              checked={form.is_active ?? true}
              onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
            />
            مفعّل
          </label>

          <div className="flex justify-end gap-2 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setModalOpen(false)}
            >
              إلغاء
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? 'جارِ الحفظ…' : 'حفظ'}
            </Button>
          </div>
        </form>
      </Modal>
    </>
  )
}

function Field({
  label,
  children,
}: {
  label: string
  children: React.ReactNode
}) {
  return (
    <div>
      <label className="mb-1 block text-sm font-semibold text-slate-600">
        {label}
      </label>
      {children}
    </div>
  )
}
