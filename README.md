# Лаборатори №5: API систем тест — Postman ба Newman

**Хичээл:** F.CSA313 — Программ хангамжийн чанарын баталгаа ба тест (2026)  
**Оюутан:** Б. Мөнгөншагай  
**Оюутны код:** B232270013

## Зорилго

Лекц 5-ын тест дизайны таван алхмыг `POST /registrations` функцэд хэрэгжүүлж, Postman collection-ийг Newman-аар автоматжуулна. Багшийн өгсөн `server.js`-ийг өөрчлөлтгүй ашиглана.

## Ажиллуулах

Node.js 16+ болон Newman 6 шаардлагатай.

```sh
npm ci
node server.js
```

Өөр терминалд `npx newman run lab05-collection.json` ажиллуулна.

## Тест дизайны 5 алхам

1. Бие даан тестлэгдэх функц: `POST /registrations`; PUT endpoint-ууд зөвхөн initialization, POST-ийн хариу oracle болно.
2. Сонголтууд: оюутны оршин байх ба төлөв, үзсэн хичээл, хичээлийн оршин байх, урьдач нөхцөл, хүсэлтийн формат.
3. Төлөөлөх утгууд: доорх эквивалент анги тус бүрээс нэг утгыг сонгов.
4. Спецификаци: амжилт, дөрвөн бизнес алдаа, давхар алдаа, хязгаарын тохиолдлуудыг сонгов.
5. Бодит тест: спецификаци бүр тусдаа folder, өөрийн PUT setup, POST хүсэлт, `pm.test` oracle-уудтай байна.

## Сонголт ба төлөөлөх утга

| Сонголт | Эквивалент анги | Төлөөлөх утга |
|---|---|---|
| studentID | Байгаа, идэвхтэй | `S01`, status=`active` |
| studentID | Байгаа, идэвхгүй | `S03`, status=`inactive` |
| studentID | Байхгүй | `missing_student_{{$guid}}`, PUT хийхгүй |
| Оюутны үзсэн хичээл | Урьдач нөхцөл хангана | `["CS201", "CS202"]` |
| Оюутны үзсэн хичээл | Урьдач нөхцөл хангахгүй | `[]` эсвэл `["CS201"]` |
| courseID | Байгаа | `C01`, PUT setup-тай |
| courseID | Байхгүй | `missing_course_{{$guid}}`, PUT хийхгүй |
| Хичээлийн урьдач нөхцөл | Бүгд үзсэн | required=`["CS201", "CS202"]`, taken ижил |
| Хичээлийн урьдач нөхцөл | Огт үзээгүй | required=`["CS201", "CS202"]`, taken=`[]` |
| Хичээлийн урьдач нөхцөл | Зарим нь үзсэн | required=`["CS201", "CS202"]`, taken=`["CS201"]` |
| Хичээлийн урьдач нөхцөл | Урьдач нөхцөлгүй | required=`[]`, taken=`[]` |
| Хүсэлтийн талбар | studentID дутуу | `{"courseID":"C10"}` |
| Хүсэлтийн талбар | courseID дутуу | `{"studentID":"S11"}` |
| Хүсэлтийн талбар | Хоосон ID | `{"studentID":"","courseID":"C12"}` |
| Хүсэлтийн формат | Буруу JSON | `{"studentID":` |

Үзсэн хичээл ба урьдач нөхцөл нь хоорондоо хамааралтай тул бүх сонголтын Cartesian үржвэрийг механикаар авахгүй. Байхгүй оюутанд status/coursesTaken, байхгүй хичээлд prerequisites оноох боломжгүй. Урьдач нөхцөлгүй хичээлд «зарим нь үзсэн» буюу «дутуу» анги боломжгүй.

## Спецификаци

| ID | Нөхцөл ба төлөөлөх оролт | HTTP | result | Нэмэлт oracle |
|---|---|---:|---|---|
| T01 | Active S01; CS201, CS202 үзсэн; C01 хоёр prerequisite-тай | 201 | OK | registrationID тоо |
| T02 | Оюутан байхгүй; C02 байгаа | 200 | ERROR_NO_STUDENT | — |
| T03 | Inactive S03; C03 байгаа; prerequisites хангана | 200 | ERROR_INACTIVE_STUDENT | — |
| T04 | Active S04; хичээл байхгүй | 200 | ERROR_NO_COURSE | — |
| T05 | Active S05; taken=[]; C05 requires CS201, CS202 | 200 | ERROR_PREREQUISITES | missing=[CS201, CS202] |
| T06 | Active S06; taken=[CS201]; C06 requires CS201, CS202 | 200 | ERROR_PREREQUISITES | missing=[CS202] |
| T07 | Оюутан, хичээл хоёул байхгүй | 200 | ERROR_NO_STUDENT | Алдааны дараалал |
| T08 | Inactive S08; хичээл байхгүй | 200 | ERROR_INACTIVE_STUDENT | Алдааны дараалал |
| T09 | Active S09; taken=[]; C09 prerequisites=[] | 201 | OK | registrationID тоо |
| T10 | Student/course setup байгаа; POST-д studentID орхисон | 400 | ERROR_BAD_REQUEST | — |
| T11 | Student/course setup байгаа; POST-д courseID орхисон | 400 | ERROR_BAD_REQUEST | — |
| T12 | Student/course setup байгаа; POST-д studentID="" | 400 | ERROR_BAD_REQUEST | — |
| T13 | Student/course setup байгаа; POST body=`{"studentID":` | 400 | ERROR_BAD_JSON | — |

T07, T08-ын давхар алдааны хүлээлтийг серверийн шалгалтын дарааллаас таамаглаж, дараа нь бодит Newman ажиллуулалтаар батална: талбар → оюутан байгаа эсэх → active эсэх → хичээл байгаа эсэх → prerequisites.
